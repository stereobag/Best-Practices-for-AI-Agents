# Dive Into Claude Code: Architecture & Design Space

*Source: "Dive into Claude Code: The Design Space of Today's and Future AI Agent Systems" — Liu, Zhao, Shang, Shen (MBZUAI / UCL) — arXiv:2604.14228*

*Methodology: Analysis of Claude Code TypeScript source (v2.1.88, ~1,884 files, ~512K lines) + comparison with OpenClaw open-source agent system*

---

## Paper Summary

The core insight: **Claude Code is a simple while-loop that calls the model, runs tools, and repeats. ~98.4% of the codebase is operational infrastructure, not AI decision logic.** The authors identify five human values → thirteen design principles → specific implementation choices, then compare Claude Code with OpenClaw to show how the same design questions produce different answers under different deployment contexts.

---

## Part 1: Five Values and Thirteen Design Principles

### Five Foundational Values

| Value | Description |
|---|---|
| **Human Decision Authority** | Humans retain ultimate authority via a principal hierarchy (Anthropic → operators → users). Observed: users approve 93% of permission prompts — so the system restructures to sandboxing/auto-classifiers rather than more warnings. |
| **Safety, Security, and Privacy** | Protects humans and their infrastructure even when the user is inattentive. Distinct from authority: safety is the system's obligation when the human's power lapses. Auto-mode threat model targets 4 risks: overeager behavior, honest mistakes, prompt injection, model misalignment. |
| **Reliable Execution** | Does what the human actually meant, stays coherent across context window boundaries, session resumption, and multi-agent delegation. Verifies work before declaring success. |
| **Capability Amplification** | Materially increases what the human can accomplish per unit of effort. Anthropic's own survey of 132 engineers documents measurable productivity gains. |
| **Contextual Adaptability** | Adjusts to different deployment contexts, user preferences, and project requirements via transparent file-based configuration. |

### Evaluative Lens: Long-Term Human Capability

A sixth concern applied as a cross-cutting evaluative lens (not a design value): **does short-term amplification come at the cost of long-term human understanding?** Key findings: developers in AI-assisted conditions score 17% lower on comprehension tests; Cursor adoption across 807 repositories showed velocity spikes that dissipated to baseline by month three while complexity rose.

---

### Thirteen Design Principles (Table 1)

| Principle | Values Served | Design Question |
|---|---|---|
| **Deny-first with human escalation** | Authority, Safety | Unrecognized actions: allowed, blocked, or escalated? |
| **Graduated trust spectrum** | Authority, Adaptability | Fixed permission level or a spectrum users traverse over time? |
| **Defense in depth with layered mechanisms** | Safety, Authority, Reliability | Single safety boundary or multiple overlapping ones? |
| **Externalized programmable policy** | Safety, Authority, Adaptability | Hardcoded policy or externalized configs with lifecycle hooks? |
| **Context as scarce resource with progressive management** | Reliability, Capability | Single-pass truncation or graduated pipeline? |
| **Append-only durable state** | Reliability, Authority | Mutable state, snapshots, or append-only logs? |
| **Minimal scaffolding, maximal operational harness** | Capability, Reliability | Invest in scaffolding-side reasoning or operational infrastructure? |
| **Values over rules** | Capability, Authority | Rigid decision procedures or contextual judgment with deterministic guardrails? |
| **Composable multi-mechanism extensibility** | Capability, Adaptability | One unified extension API or layered mechanisms at different context costs? |
| **Reversibility-weighted risk assessment** | Capability, Safety | Same oversight for all actions or lighter for reversible/read-only ones? |
| **Transparent file-based configuration and memory** | Adaptability, Authority | Opaque database, embedding-based retrieval, or user-visible version-controllable files? |
| **Isolated subagent boundaries** | Reliability, Safety, Capability | Subagents share parent context/permissions or operate in isolation? |
| **Graceful recovery and resilience** | Reliability, Capability | Fail hard on errors or recover and reserve human attention for unrecoverable situations? |

---

## Part 2: System Architecture

### Seven-Component High-Level Structure

```
User → Interfaces → Agent Loop → Permission System → Tools → Execution Environment
                         ↕
                  State & Persistence
```

| Component | Source File(s) | Description |
|---|---|---|
| User | — | Submits prompts, approves permissions, reviews output |
| Interfaces | — | Interactive CLI, headless CLI (`claude -p`), Agent SDK, IDE/Desktop/Browser — all feed the same loop |
| Agent loop | `query.ts` | `queryLoop()` async generator — the core while-loop |
| Permission system | `permissions.ts`, `types/hooks.ts` | Deny-first rule evaluation + auto-mode ML classifier + hook-based interception |
| Tools | `tools.ts` | Up to 54 built-in tools (19 unconditional, 35 conditional on feature flags) + MCP tools |
| State & persistence | `sessionStorage.ts`, `history.ts` | Append-only JSONL session transcripts, global prompt history, subagent sidechain files |
| Execution environment | `BashTool.tsx`, `src/remote/`, `mcp/client.ts` | Shell execution with optional sandboxing, filesystem, web fetching, MCP server connections |

### Five-Layer Subsystem Architecture

```
Surface Layer:    Interactive CLI | IDE/Desktop/Browser | Headless CLI | Agent SDK
                        ↓
Core Layer:       Agent Loop | Compaction Pipeline
                        ↓
Safety/Action:    Permission System + Auto Classifier | Hook Pipeline
                  Extensibility (plugins & skills) | Built-in Tools | MCP Tools | Subagent spawning | Shell sandbox
                        ↓
Backend Layer:    Execution Backends | External Resources
                        ↕
State Layer:      Context Assembly | Runtime State | Session Persistence
```

### The Agentic Query Loop (One Turn)

```python
while not stopped:
    # a. Assemble — build what the model sees
    context = assemble(system_prompt, tool_schemas, history, hook_additions)
    
    # b. Model — pick the next action
    action = model(context, tools)
    if action.is_text_only():
        stopped = run_stop_hooks(action)
        continue
    
    # c. Execute — gate and run the tool call
    if not permitted(action):  # deny-first permission check
        continue
    action = run_pre_tool_hooks(action)   # block/rewrite
    result = execute(action)              # tool runs here
    result = run_post_tool_hooks(result)  # mutate/annotate
    history.append(action, result)
```

**Stop conditions:** (1) no tool use, (2) max turns, (3) context overflow, (4) hook intervention, (5) explicit abort.

**Design question — where does reasoning live?** Model reasons; harness executes. The model emits `tool_use` blocks; the harness parses, permission-checks, and dispatches. The model never directly accesses the filesystem, runs shells, or makes network requests. This separation means a compromised model cannot override sandboxing — it can only interact via the structured `tool_use` protocol that the harness validates.

---

## Part 3: Permission and Safety System

### Seven Permission Modes

| Mode | Description |
|---|---|
| `plan` | Model must create a plan; execution proceeds only after user approval |
| `default` | Standard interactive use; most operations require user approval |
| `acceptEdits` | Edits within working directory + specific filesystem shell commands auto-approved; other shell requires approval |
| `auto` | ML-based classifier evaluates requests not passing fast-path checks (gated by `TRANSCRIPT_CLASSIFIER` feature flag) |
| `dontAsk` | No prompting, but deny rules still enforced |
| `bypassPermissions` | Skips most permission prompts; safety-critical checks and bypass-immune rules still apply |
| `bubble` | Internal-only: subagent permission escalation to parent terminal |

### Seven-Layer Authorization Pipeline

**A single action must pass ALL applicable layers (any one can block):**

1. **Tool pre-filtering** (`tools.ts`): Blanket-denied tools stripped from model's view before any call — model never attempts to invoke them
2. **Deny-first rule evaluation** (`permissions.ts`): Deny rules always take precedence over allow rules, even more specific allow rules. A broad deny cannot be overridden by a narrow allow.
3. **PreToolUse hooks**: Can deny, ask, or rewrite tool input parameters
4. **Permission handler** (4 paths): Coordinator (multi-agent), Swarm worker, Speculative classifier (BashTool), Interactive (standard dialog)
5. **Auto-mode ML classifier** (`yoloClassifier.ts`): When `TRANSCRIPT_CLASSIFIER` enabled — races pre-started classification against a timeout
6. **Shell sandboxing** (`shouldUseSandbox.ts`): Filesystem and network isolation independent of application-level permission model
7. **PostToolUse hooks**: Can observe, annotate, or stop continuation

**Key insight:** When a deny rule blocks an action, the model receives the denial reason, revises its approach, and attempts a safer alternative — permission enforcement shapes behavior rather than simply halting it.

**Security note:** Commands with >50 subcommands fall back to a single generic approval prompt (per-subcommand parsing caused UI freezes) — a documented tension between safety and performance.

---

## Part 4: Extensibility — Four Mechanisms

```
Injection Point     Mechanism    Context Cost    Unique Capability
─────────────────────────────────────────────────────────────────
assemble():         Skills       Low             Domain-specific instructions + meta-tool invocation
  context           MCP servers  High            External service integration (multi-transport)
  injection         Plugins      Medium          Multi-component packaging + distribution

execute():          Hooks        Zero by default  Lifecycle interception + event-driven automation
  pre/post tool
```

### Extension Mechanism Details

**MCP Servers** — `model()` tool pool injection. High context cost (tool schemas). Integrates external services via 8+ transport variants (stdio, SSE, HTTP, WebSocket, SDK, IDE adapters).

**Plugins** (`PluginManifestSchema`) — Packaging + distribution layer. Ten component types: commands, agents, skills, hooks, MCP servers, LSP servers, output styles, channels, settings, user configuration.

**Skills** — Low context cost (descriptions only). Model calls `SkillTool` meta-tool by name. Hooks register dynamically on invocation.

**Hooks** — 27 hook events: tool authorization (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied), session lifecycle (SessionStart, SessionEnd, Setup, Stop), user interaction (UserPromptSubmit, Elicitation), subagent coordination (SubagentStart, SubagentStop, TeammateIdle, TaskCreated, TaskCompleted), context management (PreCompact, PostCompact, InstructionsLoaded), workspace events (CwdChanged, FileChanged, WorktreeCreate, WorktreeRemove), notifications.

Four hook command types: shell (`type: command`), LLM prompt (`type: prompt`), HTTP (`type: http`), agentic verifier (`type: agent`).

### Tool Pool Assembly (5 steps)

1. Base tool enumeration: up to 54 tools (19 always included: BashTool, FileReadTool, AgentTool, SkillTool, WebFetchTool, WebSearchTool, etc.; 35 conditional)
2. Mode filtering: `CLAUDE_CODE_SIMPLE` mode = only Bash, Read, Edit
3. Deny rule pre-filtering: strips blanket-denied tools before model sees them
4. MCP tool integration: merged into flat pool with built-in tools
5. Deduplication: built-in tools take precedence over MCP tools

---

## Part 5: Context Construction and Memory

### Context Window Assembly (6 layers, loaded in order)

```
(1) System Layer [startup]:    System prompt, skill descriptions, environment info, MCP tool names, output styles
(2) Project Config [startup/lazy]: CLAUDE.md hierarchy (5 levels), path-scoped rules (.claude/rules/*)
(3) Memory [startup]:          Auto memory, compact summary (replaces long history)
(4) Conversation [per-turn]:   Conversation history, subagent summaries
(5) Runtime [during execution]: Read files, command outputs, tool results
(6) On-Demand [lazy]:          Deferred tool definitions (full schemas loaded only when needed via ToolSearch)
```

### CLAUDE.md Four-Level Hierarchy

| Level | Path | Scope |
|---|---|---|
| **Managed memory** | `/etc/claude-code/CLAUDE.md` | OS-level policy for all users |
| **User memory** | `~/.claude/CLAUDE.md` | Private global instructions |
| **Project memory** | `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md` | Instructions checked into codebase |
| **Local memory** | `CLAUDE.local.md` | Gitignored, private project-specific |

**Critical distinction:** CLAUDE.md content is delivered as *user context* (a conversational user message), not as system prompt. This means compliance with CLAUDE.md instructions is **probabilistic**, not guaranteed. Permission rules (evaluated deny-first) provide the **deterministic** enforcement layer. This is a deliberate separation: guidance (probabilistic) vs. enforcement (deterministic).

Files load in reverse priority order — later-loaded files receive more model attention. Nested directory files load lazily when the agent reads files in matching directories, so the instruction set can evolve during a conversation.

### Five-Layer Context Compaction Pipeline

Five shapers execute sequentially before every model call, from lightest to heaviest:

1. **Budget reduction** (`applyToolResultBudget()`): Per-message size limits on tool results; oversized outputs replaced with content references
2. **Snip** (history trimming): Trims oldest messages while preserving coherence
3. **Microcompact**: Cache-aware partial compression; behavior influenced by prompt caching state
4. **Context collapse** (gated by `CONTEXT_COLLAPSE`): Read-time projection over conversation history — "Nothing is yielded; the collapsed view is a read-time projection over the REPL's full history. Summary messages live in the collapse store, not the REPL array." Does not mutate stored history; replaces `messagesForQuery` with projected view.
5. **Auto-compact**: Full model-generated summary via `compactConversation()`. Fires only when context still exceeds pressure threshold after all four previous shapers have run. Executes `PreCompact` hooks, creates summary, calls model.

**Recovery mechanisms:** Max output tokens escalation (up to 3 retries), reactive compaction, prompt-too-long handling (context-collapse overflow → reactive compaction → terminate), streaming fallback, fallback model.

### Context-as-Bottleneck Design Decisions

- **CLAUDE.md lazy loading**: Nested-directory files load only when agent reads files there
- **Deferred tool schemas**: Full schemas loaded on demand via ToolSearch
- **Subagent summary-only return**: Subagents return only summary text to parent, not full conversation history
- **Per-tool-result budget**: Individual tool results capped at configurable size

---

## Part 6: Subagent Delegation

**Subagents return only summary text to the parent, not their full conversation history.** Sidechain transcripts store each subagent's conversation in a separate file, preventing subagent content from inflating the parent context.

**Permission model:** Subagents use `bubble` mode internally for permission escalation to the parent terminal. Permission levels are not restored across session boundaries.

**Execution:** `AgentTool.tsx` manages subagent dispatch. The `runAgent.ts` file implements a 21-parameter agent lifecycle.

**Tool orchestration:** Two parallel execution paths:
- `StreamingToolExecutor`: Begins executing tools as they stream in (reduces latency). Sibling abort controller fires when any Bash tool errors. Results emitted in request order even when running in parallel.
- `runTools()` fallback: Iterates over partitions produced by `partitionToolCalls()`

Read-only operations run in parallel; state-modifying operations (shell commands) are serialized.

---

## Part 7: Claude Code vs. OpenClaw — Architectural Contrast

Both systems face the same recurring design questions but produce different answers based on deployment context:

| Design Question | Claude Code | OpenClaw |
|---|---|---|
| **Safety model** | Per-action deny-first evaluation + ML classifier | Perimeter-level access control |
| **Core execution** | Single CLI loop (`queryLoop()`) | Embedded runtime within a gateway control plane |
| **Context management** | 5-layer compaction pipeline | Gateway-wide capability registration |
| **Extension model** | 4 layered mechanisms at different context costs | Structured long-term memory within multi-channel gateway |
| **Deployment target** | CLI / IDE integration | Multi-channel personal assistant gateway |

The two systems can compose: OpenClaw can host Claude Code as an external harness via ACP (Agent Communication Protocol).

---

## Part 8: AI Coding Tool Taxonomy

| Category | Examples | Pattern |
|---|---|---|
| Inline completion | Copilot, Tabnine | Editor plugin |
| Chat-integrated | Cursor, Windsurf, Cody | IDE-coupled product |
| Agentic CLI | Claude Code, Codex CLI, Aider | Tool-use loop |
| Fully autonomous | Devin, SWE-Agent, OpenHands | Sandbox + planning |

Claude Code shares features with higher-autonomy agents (auto-mode classifier, background agent execution, remote environments) but retains interactive approval by default.

**Context management approaches:**

| Approach | Mechanism | Granularity |
|---|---|---|
| Simple truncation | Drop oldest messages | Coarse |
| Sliding window | Fixed-size recent history | Medium |
| RAG | Retrieve relevant snippets | Fine |
| Single summarization | One-pass compress | Coarse |
| **Graduated compaction** | **Multi-layer pipeline (Claude Code)** | **Very fine** |

---

## Part 9: Six Open Research Directions

### 1. Silent Failure and the Observability–Evaluation Gap
Most deployed agent failures are silent mistakes, not crashes. The generator–evaluator separation (Section 12.1 references Rajasekaran's harness design guidance) may need to live inside the harness as additional hook events, or outside as a separate evaluation layer. Current 27-hook pipeline may or may not have sufficient context-cost envelope to host such scaffolding.

### 2. Cross-Session Persistence and Longitudinal Relationships
Between CLAUDE.md (static instructions) and session JSONL transcripts lies an open design space: durable state that is neither static instruction nor single session transcript. The "accumulating layer" (reusable procedural traces, self-reflection traces) is the natural next step.

### 3. Harness Boundary Evolution
Anthropic's Managed Agents work describes virtualizing agent components (session, harness, sandbox) so "each became an interface that made few assumptions about the others" — analogous to how OSes virtualized hardware. The architecture documented in the paper is "a snapshot of a co-evolving system rather than a fixed optimum."

### 4. Horizon Scaling — From Session to Scientific Program
How the architecture (whose primary units are turn, session, and sub-agent) continues to support long-horizon dependability as autonomous work extends beyond a single session. KAIROS feature (proactivity + terminal focus awareness + SleepTool economic throttling) points toward one answer.

### 5. Governance and Compliance
The EU AI Act's full applicability in August 2026 (GPAI Code of Practice). Current architecture: internally auditable via session transcripts but not yet externally auditable in forms that emerging frameworks contemplate. The values-over-rules principle may need explicit rule articulation for compliance review.

### 6. Long-Term Human Capability Preservation
The architecture provides limited mechanisms that explicitly preserve long-term human understanding, codebase coherence, or the developer pipeline. Treating this sustainability gap as a first-class design problem rather than a downstream evaluation metric is the key open question.

---

## Part 10: Three Recurring Cross-Cutting Design Commitments

### 1. Graduated Layering Over Monolithic Mechanisms
Safety (7 layers), context management (5 compaction stages + lazy loading + deferred schemas + summary-only returns), extensibility (4 mechanisms at different context costs). Each trades simplicity and debuggability for defense in depth.

### 2. Append-Only Designs That Favor Auditability
Session transcripts: append-only JSONL with read-time chain patching. Permissions: not restored across session boundaries. Context compaction: read-time projections over full history, not destructive edits. Cost: richer structured queries require post-hoc reconstruction.

### 3. Model Judgment Within a Deterministic Harness
~1.6% of codebase is AI decision logic; ~98.4% is operational infrastructure. The harness creates conditions (tool routing, permission enforcement, context assembly, recovery logic) under which the model decides. The model retains full latitude over which tools to invoke and in what order.

---

## Appendix: Key Source Files

| File | Size | Responsibility |
|---|---|---|
| `main.tsx` | 804KB | Entry point, mode dispatch, setup |
| `query.ts` | 68KB | Core agent loop, 5 context shapers |
| `QueryEngine.ts` | 47KB | SDK/headless conversation wrapper |
| `Tool.ts` | 30KB | Tool interface, types, utilities |
| `history.ts` | 14KB | Global prompt history |
| `mcp/client.ts` | Large | MCP client (8+ transport variants) |
| `compact.ts` | Large | Compaction engine |
| `AgentTool.tsx` | Large | Agent tool, subagent dispatch |
| `runAgent.ts` | Large | 21-parameter agent lifecycle |

Source: ~1,884 files, ~512K lines of TypeScript (v2.1.88). GitHub: https://github.com/VILA-Lab/Dive-into-Claude-Code
