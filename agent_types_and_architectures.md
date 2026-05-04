# AI Agent Types and Architectures for Developer Productivity
## Last Updated: 2026-03-21

---

## The 2026 Agent Reality

From Anthropic's 2026 Agentic Coding Trends Report:
- Agents now complete 20 autonomous actions before requiring human input (double from 6 months prior)
- Engineers use AI in ~60% of their work but fully delegate only 0-20% of tasks
- Multi-agent systems report 3x faster task completion and 60% better accuracy vs. single-agent approaches (Gartner, 2025)
- 1,445% surge in enterprise multi-agent system inquiries from Q1 2024 to Q2 2025

---

## Agent Architecture Patterns

### Pattern 1: Orchestrator + Specialized Subagents

The most powerful and scalable pattern for complex development workflows.

```
[Orchestrator Agent]
       |
   ----+----
   |   |   |
[FE] [BE] [QA]  [Docs] [Security]
Agent Agent Agent  Agent   Agent
```

**How it works:**
- Orchestrator acts as "project manager" — breaks down tasks, assigns to specialists, aggregates results
- Subagents are specialized: each handles a specific domain
- Agents communicate through coordination protocols
- Orchestrator handles conflict resolution and final synthesis

**Best for:** Full-feature development, large refactors, multi-service changes

**Tools that support this:** Claude Code (Agent Teams), LangGraph, CrewAI

---

### Pattern 2: Sequential Pipeline

Agents chain in a linear order — each agent's output feeds the next.

```
[Requirements] → [Architecture] → [Implementation] → [Testing] → [Review] → [Documentation]
```

**How it works:**
- Well-defined handoffs between stages
- Each stage has clear input/output contracts
- Easy to audit and debug
- Natural fit for compliance-heavy environments

**Best for:** Regulated industries, repeatable feature types, onboarding automation

---

### Pattern 3: Concurrent Exploration

Multiple agents work the same problem simultaneously from different angles, results are synthesized.

```
          [Problem]
         /    |    \
   [Agent A] [Agent B] [Agent C]
   approach1 approach2 approach3
         \    |    /
        [Synthesis]
```

**Best for:** Architecture decisions, security audits, code review, performance optimization options

---

### Pattern 4: Supervisor-Critic Loop

One agent generates, another critiques — loops until quality threshold is met.

```
[Generator Agent] ←→ [Critic Agent]
        ↓ (when critic approves)
   [Output]
```

**Best for:** Code quality enforcement, test generation, documentation writing

---

## Catalog of Agents to Build

### Development Lifecycle Agents

#### 1. PR Automation Agent
**Purpose:** Automate PR creation, description, and initial review
**Inputs:** Diff, commit messages, related ticket
**Outputs:** PR description, risk assessment, test summary, reviewer suggestions
**Trigger:** Git push to feature branch
**Tools:** Claude Code / GitHub Actions + Copilot
**ROI:** Saves 15-30 min per PR; improves PR quality for review

#### 2. Code Review Agent
**Purpose:** First-pass code review before human reviewers
**Inputs:** PR diff, codebase context, coding standards
**Outputs:** Inline comments on: security issues, performance problems, missing tests, style violations
**Trigger:** PR opened/updated
**Tools:** Claude Code, Codex, or GitHub Copilot (Agent Mode)
**ROI:** Catches 60-70% of common issues before human review

#### 3. Test Generation Agent
**Purpose:** Automatically generate unit, integration, and edge-case tests
**Inputs:** New/modified functions + codebase context
**Outputs:** Test file with unit tests, edge cases, and mock setups
**Trigger:** PR opened, or on-demand
**Tools:** Claude Code (highest quality), Cursor
**ROI:** Brings test coverage from 60% → 85%+ with minimal developer effort

#### 4. Dependency Update Agent
**Purpose:** Keep dependencies current with automated PRs
**Inputs:** package.json / requirements.txt / go.mod + changelog data
**Outputs:** Upgrade PRs with summary of breaking changes and required code updates
**Trigger:** Weekly scheduled run
**Tools:** Claude Code + Renovate Bot
**ROI:** Eliminates manual dependency management; reduces security vulnerabilities

#### 5. Documentation Agent
**Purpose:** Keep docs in sync with code changes
**Inputs:** Code diff, existing docs, API specs
**Outputs:** Updated README, API docs, inline comments, changelog entries
**Trigger:** PR merge to main
**Tools:** Claude Code
**ROI:** Eliminates documentation lag; improves onboarding time

---

### Quality & Security Agents

#### 6. Security Audit Agent
**Purpose:** Automated security review of every PR
**Inputs:** Code diff + security policy documents
**Outputs:** Security issues flagged with severity (CVSS score), remediation suggestions
**Trigger:** PR opened
**Tools:** Claude Code (best security track record)
**ROI:** Catches OWASP Top 10 issues before they reach staging

#### 7. Performance Regression Agent
**Purpose:** Detect performance regressions introduced by code changes
**Inputs:** PR diff + benchmark results
**Outputs:** Performance delta report, slowdown attribution, optimization suggestions
**Trigger:** PR opened on performance-sensitive paths
**Tools:** Claude Code + custom benchmarking harness
**ROI:** Prevents performance regressions from reaching production

#### 8. Quality Gate Agent
**Purpose:** Enforce quality standards before merge — refuses to approve until all checks pass
**Inputs:** Test results, coverage report, linting output, security scan
**Outputs:** Pass/fail decision with detailed remediation plan
**Trigger:** Pre-merge check
**Tools:** Claude Code, Codex
**ROI:** Reduces post-deploy incidents; enforces standards consistently

---

### Developer Support Agents

#### 9. Onboarding Agent
**Purpose:** Guide new developers through codebase ramp-up
**Inputs:** Developer questions, codebase, architecture docs
**Outputs:** Contextual answers, code walkthroughs, suggested starting tasks
**Trigger:** On-demand (Slack bot or IDE integration)
**Tools:** Claude Code with RAG over internal docs
**ROI:** Reduces new developer ramp-up from 3 months → 4-6 weeks

#### 10. Incident Response Agent
**Purpose:** Assist SREs during production incidents
**Inputs:** Error logs, runbooks, system metrics, recent deployments
**Outputs:** Root cause hypotheses, remediation steps, rollback recommendations
**Trigger:** PagerDuty/OpsGenie alert
**Tools:** Claude Code
**ROI:** Reduces MTTR by 30-50%

#### 11. Architecture Decision Agent
**Purpose:** Help developers make informed architectural decisions
**Inputs:** Problem description, existing architecture, constraints
**Outputs:** Option analysis with tradeoffs, recommendation, implementation sketch
**Trigger:** On-demand
**Tools:** Claude Code (deepest reasoning)
**ROI:** Reduces architecture review cycles; improves decision quality

---

### ML-Specific Agents

#### 12. Experiment Setup Agent
**Purpose:** Scaffold ML experiments from high-level descriptions
**Inputs:** Model type, dataset description, evaluation criteria
**Outputs:** Training script, evaluation harness, experiment tracking setup, Dockerfile
**Trigger:** On-demand
**Tools:** Claude Code + Jupyter AI

#### 13. Training Debug Agent
**Purpose:** Diagnose training instabilities and poor convergence
**Inputs:** Training logs, loss curves, model config, dataset stats
**Outputs:** Diagnosis of likely issues + prioritized fix recommendations
**Trigger:** On-demand during training runs
**Tools:** Claude Code

#### 14. Auto-EDA Agent
**Purpose:** Automated exploratory data analysis
**Inputs:** Dataset (CSV, Parquet, SQL query)
**Outputs:** Statistical summary, visualizations, data quality report, feature recommendations
**Trigger:** On-demand or on new dataset arrival
**Tools:** Claude Code + Jupyter AI

---

## Orchestration Frameworks

### LangGraph
- **Strength:** Production-grade, stateful workflows; best when failure costs are high
- **Use when:** Building pipelines that run automatically in CI/CD; enterprise reliability required
- **Weakness:** Steeper learning curve

### CrewAI
- **Strength:** Fast to build multi-agent teams for business workflow automation
- **Use when:** Quickly automating business workflows; team of specialized agents
- **Weakness:** Less control over low-level orchestration behavior

### PydanticAI
- **Strength:** Strong type guarantees; TypeScript-style safety for agent pipelines
- **Use when:** Teams prioritizing correctness and type safety in agent outputs
- **Weakness:** Newer, smaller ecosystem

### Claude Agent Teams (Native)
- **Strength:** Native integration with Claude Code; no extra framework needed
- **Use when:** Claude Code is your primary tool; spawning parallel subagents for complex tasks

### LangChain Open SWE (New — March 17, 2026)
- **Strength:** Open-source framework capturing the converged architecture from Stripe Minions, Ramp Inspect, and Coinbase Cloudbot — three teams that built internal coding agents independently and arrived at the same pattern
- **Use when:** Building an internal autonomous coding agent for asynchronous task dispatch; Slack-first invocation; cloud sandbox isolation required
- **Key architectural elements:**
  - Isolated cloud sandboxes with full permissions inside strict blast-radius boundaries (Stripe: AWS EC2 devboxes; Ramp: Modal containers; Coinbase: custom)
  - Curated toolsets — Stripe's agents have ~500 tools, carefully selected not accumulated
  - Slack-first invocation — all three systems use Slack as the primary developer interface
  - Subagent orchestration — top-level orchestrator spawns specialized subagents per task phase
- **Source:** [LangChain Open SWE blog](https://blog.langchain.com/open-swe-an-open-source-framework-for-internal-coding-agents/); [DevOps.com analysis](https://devops.com/open-swe-captures-the-architecture-that-stripe-coinbase-and-ramp-built-independently-for-internal-coding-agents/)

---

## Agentic Engineering vs. Vibe Coding (Addy Osmani, 2026)

The most important practitioner framework for professional AI use in 2026 comes from Addy Osmani (Google Chrome Engineering), who distinguishes two modes:

| Mode | Definition | Who uses it | Risk profile |
|---|---|---|---|
| **Vibe Coding** | Prompt, accept, run — no code review | Hobbyists, prototypers | High: security vulnerabilities (SQL injection, hardcoded secrets, broken auth), no production suitability |
| **Agentic Engineering** | Orchestrate agents with structured oversight; developer as architect, reviewer, decision-maker | Professional engineers | Low: systematic tests, CI, production telemetry |

### Addy Osmani's Agentic Engineering Workflow (2026)
1. Write a design doc / spec before generating any code
2. Create a "prompt plan" file — a sequence of prompts for each task (Cursor can execute them one by one)
3. Use a solid test suite as the feedback loop — tests turn unreliable agents into reliable systems
4. Connect CI: when an agent opens a PR, CI runs tests and reports failures, creating a human-overseen fix loop
5. Treat yourself as building **the factory that builds software**, not the code itself

**The Factory Model:** "You are no longer just writing code, but building the factory that builds your software — fleets of agents, each with a task, a toolbelt, context, and a feedback loop." — Addy Osmani

Source: [addyosmani.com/blog/agentic-engineering](https://addyosmani.com/blog/agentic-engineering/), [addyo.substack.com](https://addyo.substack.com/p/my-llm-coding-workflow-going-into)

---

## Vibe Coding Enterprise Risks (2026)

Enterprise teams adopting AI-generated code without professional engineering discipline face a documented set of production risks:

### Security Vulnerabilities in AI-Generated Code
- Hardcoded secrets and API keys
- SQL injection from unvalidated inputs
- Missing authentication and authorization checks
- Broken access control patterns

### "Comprehension Debt" and Haunted Codebases
- Engineers accept AI code they don't fully understand
- Bugs become harder to diagnose because no human can reason through the code path
- Refactoring becomes dangerous because architectural intent was never captured

### Required Guardrails for Enterprise AI Coding
1. **Pre-generation planning:** Use agentic planning to draft technical PRDs, define data models, and specify security guardrails before code generation begins
2. **Automated security scanning:** Every AI-generated PR runs through SAST/DAST tools before human review
3. **Mandatory human review:** No AI PR merges without engineer sign-off (validated by Stripe's 1,300 AI PR/week with 100% human review)
4. **Test coverage gates:** PRs below coverage threshold are blocked regardless of source
5. **"Vibe then verify" mindset:** AI generates the first draft; engineer verifies correctness, security, and intent

Source: [Retool vibe coding risks](https://retool.com/blog/vibe-coding-risks); [github.com/trick77/vibe-coding-enterprise-2026](https://github.com/trick77/vibe-coding-enterprise-2026); [The New Stack](https://thenewstack.io/vibe-coding-could-cause-catastrophic-explosions-in-2026/)

---

## Multi-Agent Best Practices

1. **Define clear input/output contracts** for each agent — treat them like microservices
2. **Build in human checkpoints** at high-stakes decision points (architecture changes, production deploys)
3. **Log every agent action** for auditability — especially important for compliance
4. **Start with 2-agent systems** (orchestrator + one specialist) before scaling to full teams
5. **Set maximum autonomy budgets** — define how many actions an agent can take before requiring approval
6. **Test agent pipelines in staging** with real (or realistic) data before production
7. **Monitor agent spend** — multi-agent systems can consume tokens rapidly; set budget alerts
8. **Version your agent prompts** — treat system prompts like code; use git for prompt management
9. **Curate, do not accumulate, toolsets** — Stripe discovered that carefully selected and maintained tools outperform larger unmanaged tool collections; ~500 curated tools at Stripe outperforms thousands of uncurated ones
10. **Isolate blast radius** — Run agent tasks in dedicated cloud sandboxes with full internal permissions but strict external boundaries (Ramp: Modal containers; Stripe: AWS EC2 devboxes; Coinbase: custom sandbox)

---

## Autonomous Coding Agent Benchmarks (2025–2026)

The industry has converged on SWE-Bench Verified as the primary benchmark for autonomous coding agent capability:

| Agent/System | SWE-Bench Verified Score | Notes |
|---|---|---|
| OpenHands (CodeAct 2.1) + Claude Sonnet 4.5 | 72% resolution rate | Published Nov 2025; self-hosted enterprise option available |
| Best commercial agents (early 2026) | ~65–72% | Range across leading systems |
| Human expert developers | ~86% | Upper bound benchmark |

### OpenHands for Enterprise (2026)
- Open-source platform from Princeton/Stanford research lineage
- Stateless, event-sourced, composable architecture for production reliability
- Self-hosted in customer VPC via Kubernetes for data security
- Model-agnostic (plug in Claude, GPT-4, Gemini)
- Fine-grained access control and sandboxed runtimes

Source: [arxiv.org/abs/2511.03690](https://arxiv.org/abs/2511.03690); [openhands.dev](https://openhands.dev/blog/openhands-codeact-21-an-open-state-of-the-art-software-development-agent)

---

## Observability and Monitoring for Agentic AI (AWS Prescriptive Guidance)

Source: [AWS Prescriptive Guidance — Agentic AI Serverless Observability](https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-serverless/observability-and-monitoring.html)

### Why Observability Is Different for Agentic Systems

Unlike monolithic applications, serverless and generative AI systems are distributed, stateless, and composed of ephemeral compute. This requires new thinking:

- **AI outputs are non-deterministic** — logging and inspecting LLM outputs is the only way to validate correctness over time
- **Serverless execution is trace-based, not server-based** — Lambda, Step Functions, and EventBridge don't run on fixed hosts
- **Costs are token-based** — Bedrock charges per token; Lambda and Step Functions charge per duration and execution
- **Security requires audit trails** — prompt logs, agent tool usage, and API calls must be scoped to identity and role
- **Failures impact trust** — hallucinations, delays, or incorrect tool calls degrade user confidence

Without observability: blind spots in agent behavior, undetected cost anomalies, limited insight into LLM quality, and difficulty in root-cause analysis across async workflows.

---

### Key Metrics to Monitor

| Category | Metric | Why It Matters |
|---|---|---|
| **Agent behavior** | Tool selection rate; invalid tool invocations | Reveals misalignment between intent and action |
| **Cost trends** | Inference cost per user or session | Enables FinOps reporting and tiered model routing decisions |
| **Invocation metrics** | Lambda invocations; error rate; cold starts | Validates pipeline stability and error resilience |
| **Knowledge base retrieval** | Hit/miss ratio; grounding relevance score | Measures RAG pipeline performance |
| **Latency** | Inference latency per model | Detects slowdowns in Bedrock or SageMaker; optimizes response time |
| **Prompt & response quality** | Hallucination rate; fallback rate | Ensures grounding is working and prompts behave as expected |
| **Security & access** | Agent and tool usage by IAM role | Ensures least-privilege and traceability |
| **Token usage** | Total input/output tokens (Bedrock) | Controls cost; detects prompt bloat or model misuse |
| **Workflow health** | Step Functions failures, retries, timeouts | Surfaces orchestration issues and retry loops |

---

### AWS Services for Agentic AI Observability

| Service | Purpose | Best For |
|---|---|---|
| **CloudWatch Logs** | Captures logs from Lambda, Step Functions, Bedrock Agents, API Gateway | Debugging, audit trails, user session tracing |
| **CloudWatch Metrics** | Custom + service KPIs (invocation count, duration, token count) | Dashboarding, alerts, trend analysis |
| **AWS X-Ray** | Distributed traces across Lambda, API Gateway, Step Functions | Root-cause analysis, latency tracking, dependency mapping |
| **CloudWatch Embedded Metric Format** | Structured logging for advanced metrics in log streams | Analytics without separate metrics API calls |
| **Bedrock Agent Trace + Model Invocation Logging** | Native agent execution trace, tool calls, RAG insights | Monitor agent behavior and troubleshoot failures |
| **EventBridge Pipes + Schema Registries** | Tracks and validates event formats in pipeline | Prevent malformed events; ensure contract consistency |
| **AWS CloudTrail** | Logs all API calls with identity context | Compliance, security audits, agent/tool usage by role |
| **Amazon OpenSearch** | Indexes inference responses, structured logs, audit records | Semantic search of responses; observability dashboards |
| **CloudWatch Synthetics** | Simulates traffic to test endpoints/workflows proactively | Uptime and regression monitoring across versions |

---

### Monitoring an Agent-Based Support Workflow (Stage-by-Stage)

1. **User query → API Gateway** — monitor response time and 5xx errors
2. **Pre-processor Lambda** — monitor cold starts and parsing failures
3. **Bedrock Agent** — monitor prompt, tool call traces, token cost, and latency
4. **Tool Lambda** (e.g. `getOrderStatus`) — monitor execution time and invocation count per user
5. **RAG / Knowledge Base query** — monitor relevance score and missing grounding
6. **Post-processor Lambda** — monitor schema validation and fallback triggers
7. **CloudWatch + OpenSearch logs** — monitor session logs, trace IDs, and model response quality
8. **Alarms** — alert on high failure rates, cost-per-session spikes, degraded latency

---

### Observability Best Practices (AWS)

1. **Instrument with structured logs** — enable correlation across components (user session, trace ID, model response)
2. **Use consistent logging schema** — support downstream parsing, alerting, and analytics pipelines
3. **Emit custom metrics per layer** — distinguish model-related errors from infrastructure issues
4. **Tag logs with environment and context** — filter by user role, region, version, or team
5. **Use anomaly detection alarms** — detect token surges, latency spikes, or output drift
6. **Correlate LLM response logs with downstream impact** — link agent outputs to decisions, escalations, or failures
7. **Automate weekly dashboards** — prompt cost, model usage, and fallback rates to drive accountability

> **Core principle:** In AI-driven serverless systems, you don't monitor hosts — you monitor **behavior, cost, and correctness**.

---

## Agent Production Monitoring

*Source: "Building Applications with AI Agents" — Michael Albada (O'Reilly, Ch. 10)*

### Why Agent Monitoring Is Different

Shipping agentic systems is only the halfway point. Agents behave **probabilistically** — they depend on foundation models, chain tools together, and respond to unbounded user inputs. You cannot write exhaustive tests for every scenario. That makes monitoring the nervous system of your deployed agent infrastructure.

Monitoring is not just about detecting problems — it is a **tight feedback loop** that accelerates learning and iteration. Agent failures are subtle: a tool succeeds but cascades errors; an LLM output sounds fluent yet misleads; a plan partially works but misses the goal. These mismatches rarely crash systems. Monitoring must expose them swiftly.

> **Key principle:** Every production failure is a test case. Every exemplary success is a golden path. Export both into your CI/CD corpus — this "shifts left" your monitoring strategy and continuously validates new agent versions against real-world complexity.

---

### The Reference Open Source Stack

| Tool | Role |
|---|---|
| **OpenTelemetry (OTel)** | Instrument agent workflows — traces, metrics, structured logs |
| **Loki** | Log aggregation and structured querying |
| **Tempo** | Distributed trace backend — filter by latency, error, span attributes |
| **Grafana** | Unified visualization, dashboards, and alerting |

This stack integrates with the same Prometheus/Grafana infrastructure used for production services. No separate monitoring stack needed — agents benefit from the same rigor as any other critical software service.

**Privacy note:** Logs may contain user messages, tool inputs, or LLM generations. Configure separate monitoring clusters with RBAC, encryption-at-rest, and PII redaction. OTel provides hooks for data scrubbing during span export.

---

### Metrics Taxonomy

| Layer | Metric | Why It Matters | Action |
|---|---|---|---|
| **Infrastructure** | CPU/memory, uptime, request latency (P50/P95/P99) | System health and scaling pressure | Autoscale, tune caching, trigger incident response |
| **Workflow** | Task success rate | How often agents complete intended workflows | Investigate failures or update prompts |
| **Workflow** | Token usage (workflow level) | Rapid changes indicate issues | Prune prompts or adjust model tier |
| **Workflow** | Tool call success/failure rate | Detects degraded integrations or tool misuse | Patch wrappers or fail over automatically |
| **Workflow** | Retry + fallback frequency | Identifies instability in plans or tools | Debounce retries, refine planning logic, escalate to human |
| **Output quality** | Hallucination indicator | Semantic accuracy of generated content | Introduce grounding or LLM critique steps |
| **Output quality** | Embedding drift from baseline | Distribution shifts in user inputs | Adjust workflows or fine-tune prompt |
| **User feedback** | Requery/rephrasing rate | Whether users are understood on first try | Improve intent classification |
| **User feedback** | Task abandonment rate | Workflows that confuse or frustrate users | Simplify flows, add clarification prompts |
| **User feedback** | Explicit ratings (thumbs up/down) | Qualitative assessment of helpfulness | Triage outputs for evaluation |

---

### Monitoring Stack Comparison

| Stack | Key Strength | Best For | Trade-off |
|---|---|---|---|
| **Grafana + OTel + Loki + Tempo** | Composability and visualization | Enterprise ops, no vendor lock-in | More components to manage |
| **ELK Stack** | Advanced full-text and vector search | Large-scale logs, existing ELK investments | Higher resource use (Elasticsearch is memory-intensive) |
| **Arize Phoenix** | Structured tracing + evals, Jupyter integration | Dev/ML iteration, debugging | Limited production scale; supplement not replace |
| **SigNoz** | Unified OTel-native, lightweight | Startups, ML-focused teams | Less extensible ecosystem |
| **Langfuse** | LLM-native: token cost tracking, session replay, A/B prompt testing | Semantic monitoring, dev teams | Narrower infra coverage; pair with Prometheus |

**Decision rule:** If you have an existing enterprise stack (Splunk, Datadog, New Relic), extend it with OTel instrumentation unless you need LLM-specific evals (use Langfuse/Phoenix) or advanced search (ELK). For greenfield, Grafana or SigNoz provide broad coverage.

---

### OTel Instrumentation for LangGraph

Each LangGraph node is an isolated, explicitly declared function — straightforward to instrument with OTel spans. Recommended span attributes per node type:

- **Tool-calling nodes:** tool name, method called, latency, success/failure, error codes
- **LLM generation nodes:** prompt identifier, input/output token counts, model latency, hallucination risk flag

```python
from opentelemetry import trace
tracer = trace.get_tracer("agent")

async def call_tool_node(context):
    with tracer.start_as_current_span("call_tool", attributes={
        "tool": context.tool_name,
        "input_tokens": context.token_usage.input,
        "output_tokens": context.token_usage.output,
    }):
        result = await call_tool(context)
        return result
```

Spans support: nested subspans (downstream API calls), events (fallback triggers, retries), and automatic exception capture. OTel context propagates automatically across async calls — full end-to-end trace across branched agent flows without architectural changes.

**Scoping rule:** Attach just enough context per step — user request IDs, session metadata, agent config state, skill names, evaluation signals — so failure trails are coherent and searchable. Too much detail becomes noisy; too little blocks root cause analysis.

---

### Visualization and Alerting in Grafana

Grafana connects to Loki (logs) and Tempo (traces) as native data sources. Key dashboard panels for agent systems:

- Token usage per agent per hour (detect model verbosity regressions)
- P95 latency for tool calls and planning nodes
- Task success rate by workflow or prompt template version
- Fallback frequency by tool or skill
- Embedding similarity drift of user queries over time

**Alert triggers to configure:**
- Hallucination rate exceeds 5% in the last 30 minutes
- Retry loops occur more than 3 times in a single session
- Average response time for a critical tool increases >50%
- Tool call error rate spikes above threshold

**Integrations:** PagerDuty for on-call escalation; Sentry for exception capture with stack traces and release health; AgentOps.ai as an all-in-one alternative combining tracing, metrics, evals, and alerting in a single package.

---

### Monitoring Patterns

**Shadow Mode**
Run a new agent version alongside production, processing the same inputs without serving outputs to users. Instrument both with OTel + shared request ID, label shadow spans in Loki/Tempo. Compare tool selection, latency, token usage, and hallucination frequency before any user exposure.

**Canary Deployments**
Serve a new agent version to 1–5% of real traffic. Filter all Grafana metrics and traces by version tag to compare success rates, latency, and error counts. Expand if the canary holds; roll back immediately if it regresses. Canarying provides the safety needed to iterate quickly in production.

**Regression Trace Collection**
Automatically export production failure traces (Tempo) and log snapshots (Loki) into your test suite. Production failures become test cases; exemplary successes become golden paths. Re-running exported traces after a fix validates the repair. Over time, the evaluation set reflects real-world edge cases.

**Self-Healing Agents**
Agents that read their own telemetry in real time can implement fallback mechanisms:
- Repeated tool call failures → reroute to simpler fallback plan or ask user for clarification
- Latency spikes → skip optional reasoning steps
- High hallucination scores → issue disclaimer or defer to human review

Each fallback decision should be logged and traced so teams can analyze when and why fallbacks triggered.

---

### Distinguishing True Failures from Expected Variation

A decision tree for probabilistic agent outputs:

1. Does output meet success criteria (e.g., eval score > 0.8)? → **Yes:** monitor trends, no action needed
2. **No** → Is it reproducible? (rerun 3–5 times; failure rate >80%) → **Yes:** systematic bug for engineering review
3. **Not reproducible** → Check confidence/variance (LLM score > 0.7, KL divergence < 0.2 from baseline)
   - Within bounds → expected variation, log for drift watch
   - Outside bounds → anomalous failure, check input drift (PSI > 0.1), trigger mitigation (retraining or guardrails)

---

### Detecting Distribution Shifts

**Kolmogorov-Smirnov (KS) test** — detects shifts in continuous features (query lengths, latencies):
```python
from scipy import stats
ks_stat, p_value = stats.ks_2samp(historical, current)
if ks_stat > 0.1:  # paired with p-value < 0.05
    print(f"Drift detected: KS = {ks_stat}")
```

**KL Divergence** — measures concept drift via token distribution shifts:
```python
# KL(P||Q) — higher values = greater drift from historical baseline P
# Threshold > 0.5 flags meaningful concept changes
```

**Population Stability Index (PSI)** — detects shifts in categorical variables (tool usage categories):
```python
# PSI < 0.1: stable | 0.1–0.25: monitor | > 0.25: intervene (retrain)
```

**Early warning signals:** accuracy drop >5–10% over 24-hour rolling window; task abandonment increase >15%; retry surge >20% session rate; cosine similarity of query embeddings vs. baseline falling below 0.8.

---

### Cross-Functional Metric Ownership (RACI)

Agents don't respect traditional team boundaries — a foundation model response is the product; a chain of retries is the user experience; a 5-second planning delay is often a prompt design decision.

| Metric | Product Team | ML Engineers | Infra/SRE |
|---|---|---|---|
| Latency (planning, tool calls) | A — owns user impact | R — optimizes prompts/models | R — monitors infra causes |
| Hallucination rates | C — user feedback context | A/R — owns detection/mitigation | I — alerting setup |
| Task success rate | A/R — defines success criteria | C — model improvements | I — system reliability |
| Token usage/cost | C — business impact | R — optimizes generations | A — owns budgeting/scaling |
| Distribution shifts | I — product adjustments | A/R — detects via embeddings | C — data pipeline stability |
| Fallback/retry frequency | C — UX fallbacks | R — refines planning logic | A — owns reliability |
| User feedback/sentiment | A/R — owns aggregation | C — model correlation | I — ops alerts |

**Practices that make cross-functional monitoring work:**
- Tag spans and logs with product context (feature flag, user tier, workflow ID)
- Build shared dashboards — product leads see how planning latency correlates with abandonment; ML monitors hallucination alongside user feedback; SRE alerts on token spikes and tool flakiness
- Run cross-functional triage rituals after launches or major regressions
- Hold foundation model latency to the same bar as any other service — slowness that impacts users is everyone's problem

---

## Agent Tool Accuracy Evaluation

Beyond runtime monitoring, evaluating agent quality requires systematic end-to-end testing against ground truth scenarios. The core approach: run the agent end-to-end, extract its chosen actions (tool invocations + arguments), and compare against expected outcomes.

### The Three Evaluation Metrics

| Metric | Question It Answers | What Failure Looks Like |
|---|---|---|
| **Tool Recall** | Did the planner include all expected tool invocations? | Agent skips a required step (e.g., fails to check inventory before confirming an order) |
| **Tool Precision** | Did it avoid calling tools that were unnecessary? | Agent calls redundant or irrelevant tools, increasing latency and token cost |
| **Parameter Accuracy** | For each tool, did it supply the correct arguments (e.g., the specific order ID or refund amount)? | Agent calls the right tool with wrong inputs — produces incorrect output even when planning is correct |

### Why All Three Matter Together

- **High recall + low precision** → Agent is thorough but wasteful; adds cost and latency without improving outcomes
- **High precision + low recall** → Agent is efficient but incomplete; misses required steps
- **High recall + high precision + low parameter accuracy** → Agent selects the right tools in the right order but produces wrong results — the hardest failure mode to detect without ground truth comparison
- **Parameter accuracy is the hardest to measure** — requires scenario-specific ground truth (e.g., exact order IDs, dollar amounts, customer identifiers) rather than just structural correctness

### Implementation Pattern

1. Define ground truth scenarios with expected tool call sequences and arguments
2. Run agent end-to-end against each scenario
3. Extract actual tool invocations and arguments from generated outputs
4. Compute recall, precision, and parameter accuracy per scenario
5. Track metrics over time to detect regressions as prompts or models change

> **Key insight:** An agent can pass structural evaluation (right tools, right order) while still failing on parameter accuracy. Prompt changes, model upgrades, and context window modifications can all silently degrade parameter accuracy without affecting tool selection.
