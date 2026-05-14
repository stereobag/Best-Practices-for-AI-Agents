# Agent Prompting — The PTCF Framework
<!-- Covers the PTCF (Persona, Task, Context, Format) framework for agent system prompt design, cognitive prompting patterns (CoT, ToT, few-shot), multi-agent communication protocols, production case studies, and prompt iteration methodology. -->

---

## Agent Prompting — The PTCF Framework

*Source: "30 Agents Every AI Engineer Must Build" — Packt Publishing, Ch. 3*

---

### From Instructions to Constitutions

In modern agentic systems, prompts are not transient instructions — they are the foundational logic of agent cognition. A system prompt acts as a **cognitive contract**: a preconditioned scaffold through which every user message is interpreted, ensuring the agent behaves consistently across edge cases and dynamic inputs.

The PTCF framework decomposes the system prompt into four functional pillars:

| Pillar | Question Answered | Role |
|--------|------------------|------|
| **Persona** | Who is the agent? | Defines identity, tone, authority, and behavioral stance |
| **Task** | What must the agent do? | Articulates core objectives, responsibilities, and explicit boundaries |
| **Context** | Where and under what constraints? | Encodes regulatory limits, SLAs, access controls, and operational rules |
| **Format** | How should it respond? | Specifies output structure for readability, automation, and agent chaining |

These four components form a **behavioral contract** — each must reinforce the others. Misalignment between any two components causes oscillation, scope drift, or unsafe output.

---

### PTCF Component Deep-Dives

#### Persona — Defining Agent Identity

Establishes character, tone, and behavioral stance. A strong persona increases user trust, improves task framing, and ensures consistent behavior under varied input.

**Anti-pattern — Weak persona (identity collapse):**
```
[PERSONA] You are a helpful assistant.
```
*Why it fails:* "Helpful assistant" is the model's default self-description. The agent has no defined scope, authority, or domain to defend — it will comply with any request, including off-topic ones.

**Corrected:**
```
[PERSONA] You are an enterprise SaaS onboarding specialist. You assist new
customers with product configuration, integration setup, and initial training.
You do not offer creative, personal, or general-purpose assistance outside the
product domain. When asked off-topic questions, you politely redirect to
onboarding tasks.
```

---

#### Task — Articulating the Core Mission

Defines primary objectives and the boundaries of responsibility. Without a clear task definition, agents become generalists with vague purpose, degrading both performance and safety.

**Example:**
```
Your primary mission is to resolve billing inquiries for enterprise accounts by:
- Diagnosing billing discrepancies and system errors
- Providing step-by-step resolution guidance
- Escalating complex cases to appropriate specialists
```

---

#### Context — Establishing Operational Boundaries

Provides situational awareness: regulatory constraints, SLAs, access controls, and conflict-resolution rules. Context transforms a generic tool into a domain-aware, policy-compliant actor.

**Anti-pattern — Missing context (scope ambiguity):**
```
[CONTEXT] You serve enterprise clients in the financial sector.
```
*Why it fails:* No regulatory scope, no data-handling rules, no SLA. An agent on financial data without explicit GDPR or SOC 2 guidance may log PII or suggest non-compliant actions.

**Corrected:**
```
[CONTEXT] You operate within a GDPR-compliant, SOC 2 Type II-certified
environment serving EU-based enterprise clients in financial services. You must
never store, repeat, or reference personally identifiable information. When
uncertain whether an action is compliant, default to refusal and escalate to a
human reviewer. You operate under a 4-hour SLA for Severity-1 issues.
```

> Context is not optional background — it is the agent's operational law.

---

#### Format — Ensuring Structured, Predictable Output

Defines how the agent structures its responses. Critical for systems where output is consumed by downstream agents or APIs.

**Example:**
```
Structure all interactions as follows:
1. Acknowledge the customer's concern with empathy.
2. Provide solutions in numbered, actionable steps.
3. Include relevant case numbers and documentation references.
4. Offer clear escalation pathways.
5. End with a commitment to follow-up when appropriate.
```

---

### Anti-Pattern: Misaligned PTCF Components

**Bad example — conflicting components:**
```
[PERSONA] You are a creative and experimental assistant who tries unconventional solutions.
[TASK] Help users troubleshoot enterprise billing issues.
[FORMAT] Always respond with a numbered list.
```
*Why it fails:* The persona ("creative," "experimental") conflicts with the task (structured enterprise support). The agent oscillates between whimsical and procedural behavior under ambiguous queries.

**Corrected — coherent contract:**
```
[PERSONA] You are a methodical enterprise billing specialist with five years of
experience in SaaS financial operations. Your communication is professional,
clear, and solution-oriented.

[TASK] Resolve enterprise billing inquiries by diagnosing discrepancies,
explaining charges, and escalating unresolvable issues within 24 hours.

[FORMAT] Numbered list: (1) Acknowledge concern, (2) Diagnose, (3) Resolution
or escalation path.
```

---

### PTCF Prompt Template

Fill-in-the-blanks scaffold for any PTCF-compliant system prompt:

```
[PERSONA] You are a [role/title] with [relevant expertise or experience].
Your communication style is [tone descriptor] and you approach problems
[reasoning style].

[TASK] Your primary mission is to [core objective]. You are responsible for
[specific responsibilities]. You must not [explicit boundaries].

[CONTEXT] You operate in [environment description]. Your users are [audience].
Relevant constraints include [regulatory, technical, or operational limits].
When instructions conflict, [conflict resolution rule].

[FORMAT] Structure all responses as [output structure]. Use [format
specification: JSON / Markdown / numbered list / etc.]. Maximum response
length: [token or word limit]. When uncertain, [fallback behavior].
```

---

### Cognitive Prompting Patterns

Cognitive prompting patterns go beyond defining *what* an agent does — they shape *how* it thinks. Each pattern maps to a specific PTCF component:

| Pattern | PTCF Element | Use Case | Complexity |
|---------|-------------|----------|------------|
| Capability alignment | Format | Matching prompt verbosity to agent tier | Low |
| Task decomposition | Task | Breaking ambiguous goals into sub-tasks | Medium |
| Chain-of-thought (CoT) | Format | Sequential step-by-step output | Medium |
| Tree-of-thought (ToT) | Task + Context | Parallel reasoning branches with synthesis | High |
| Few-shot learning | Context | Embedded examples guiding behavior | Low–Medium |
| Role-based persona | Persona | Identity and authority scoping | Low |

---

#### Agent Capability Spectrum

Prompt sophistication must scale with cognitive complexity:

| Level | Agent Type | Prompt Requirements |
|-------|-----------|---------------------|
| **L1** | Reactive agents | Unambiguous, directive instructions; no memory or planning |
| **L2** | Tool-using agents | Guide on what tools to use, when, and how |
| **L3** | Planning agents | Trigger structured decomposition ("think step by step") |
| **L4** | Learning agents | Metacognitive blueprints; agent reasons about its own reasoning |

LangChain's `AgentExecutor` targets L2–L3; CrewAI's multi-agent abstractions target L3–L4.

---

#### Task Decomposition

Agents must be explicitly prompted to decompose vague goals before acting. Embed decomposition behavior in PTCF:

- **Task component:** "Break down vague user requests into sequential steps before taking action."
- **Format component:** "Present your plan as a numbered list of sub-tasks, ordered by dependency."

Example: "Plan my upcoming business trip to Tokyo" → agent produces:
1. Confirm travel dates and budget
2. Search for flights
3. Check visa requirements
4. Propose itinerary

This is a planning reflex encoded into the agent's cognitive architecture, not emergent behavior.

---

#### Chain-of-Thought (CoT) Prompting

Guides the agent through a linear, step-by-step analytical process. Best for problems with a clear sequential path: arithmetic, debugging, document summarization.

```
Let me first check the user's recent activity. Then, I'll look for any
violations of the terms of service. Finally, I'll determine whether a
suspension notice was issued.
```

**Use when:** The problem has a known correct path and methodical reasoning is essential.
**Avoid when:** The question is simple/factual — CoT adds overhead with no benefit.

---

#### Tree-of-Thought (ToT) Prompting

Explores multiple reasoning branches in parallel, then synthesizes into a final answer. Mimics how a team of experts brainstorms before converging.

**Three-stage ToT process:**
1. **Decomposition** — Create virtual experts for each dimension (market, finance, marketing)
2. **Simulated discussion** — Experts evaluate and prune each other's conclusions sequentially
3. **Synthesis** — Integrate winning arguments into one coherent recommendation

**Decision guide — CoT vs. ToT:**

| Dimension | Chain-of-Thought (CoT) | Tree-of-Thought (ToT) |
|-----------|----------------------|----------------------|
| Problem structure | Sequential, ordered | Multi-path, exploratory |
| Output form | Single reasoned answer | Synthesized consensus |
| Compute cost | Low (single chain) | High (parallel branches) |
| Key failure mode | Premature commitment | Branch explosion |
| PTCF home | Format | Task + Context |
| Example use case | Root-cause diagnosis | Launch strategy design |

---

#### Few-Shot Learning

Embeds strategic examples in the **Context** component to guide reasoning and output without retraining the model.

**When to use few-shot (not RAG):**
- Context is narrow and self-contained
- Reasoning patterns can be expressed in 2–5 examples
- Latency or cost prohibits external retrieval

**Few-shot vs. RAG decision guide:**

| Dimension | Few-Shot Learning | RAG |
|-----------|------------------|-----|
| Data freshness | Static (baked in) | Dynamic (retrieved) |
| Context window cost | High (examples inline) | Lower (chunks only) |
| Setup complexity | Low | Medium–high (vector DB required) |
| Best fit | Pattern-rich, bounded tasks | Large/changing document corpora |
| Key failure mode | Context overflow | Retrieval hallucination |

**Ticket routing example — few-shot context:**
```
Example 1
- Input: "I can't log in, and I have a deadline in an hour!"
- Analysis: Account lockout with high urgency
- Classification: {"Urgency": "High", "Category": "Account Access", "Action": "Initiate Password Reset Protocol"}

Example 2
- Input: "My entire system is down and I'm losing money every minute!"
- Analysis: Total outage with financial impact
- Classification: {"Urgency": "Critical", "Category": "Outage", "Action": "Escalate to Tier-2 Engineering"}
```

The agent doesn't mimic — it generalizes. It learns to reason about intent, detect urgency, and align actions to outcomes.

---

### Multi-Agent Communication Protocols

PTCF's four pillars extend naturally to govern how agents communicate with each other:

| PTCF Component | Inter-Agent Role |
|---------------|-----------------|
| **Persona** | Agent's verifiable identity and authority within the network |
| **Task** | Purpose/intent of each message (request, alert, update) |
| **Context** | Shared metadata: timestamps, message references, priority levels |
| **Format** | Universal JSON schema — the lingua franca all agents agree on |

**Standard message schema for a financial risk network:**
```json
{
  "sender_id": "agent_alpha",
  "recipient_id": "agent_beta",
  "message_type": "risk_assessment_update",
  "timestamp": "ISO_8601_format",
  "confidence_score": 0.85,
  "data_payload": {
    "risk_category": "credit",
    "assessment_summary": "Credit risk remains low based on Q4 data.",
    "key_factors": ["stable_revenue", "low_debt_ratio"],
    "recommendations": ["maintain_current_rating"]
  },
  "context_references": ["previous_analysis_id_123"],
  "requires_response": false,
  "priority_level": "medium"
}
```

A standardized format ensures every message carries routing metadata while delivering substantive content for collaborative decision-making.

---

### Production Case Studies

#### Case Study 1: SaaS Customer Support Triage Agent
- **Problem:** 40%+ of agent time spent manually categorizing and routing tickets; high-severity issues intermittently delayed
- **PTCF:** Persona = Level-2 triage specialist with authority to assign severity tags; Task = classify → severity-score → route; Context = SLA thresholds (Sev-1: 1hr, Sev-2: 4hr, Sev-3: 24hr); Format = structured JSON (ticket_id, category, severity, assigned_queue, suggested_action)
- **Outcome:** ~60–70% reduction in manual triage time; Sev-1 tickets consistently routed within SLA window
- **Key takeaway:** Embedding SLA thresholds in the Context component eliminates the need for a separate rules engine. Structured JSON output made the agent composable with zero transformation overhead.

#### Case Study 2: Financial Compliance Review Agent
- **Problem:** Pre-screening client communications for regulatory violations; early prompts occasionally produced plausible but non-compliant guidance
- **PTCF:** Persona = compliance pre-screening specialist with no authority to provide financial advice; Task = two-pass (identify policy-relevant language → classify risk Low/Medium/High); Context = MiFID II / FCA COBS categories, explicit prohibition on advice/predictions, mandatory human escalation for High risk; Format = structured review report with risk_level, flagged_passages, and reasoning fields
- **Key takeaway:** In regulated domains, the Context component functions as a compliance guardrail. Explicit prohibitions belong in Context, not implied by Persona. The reasoning field provides the audit trail compliance teams require.

#### Case Study 3: Automated Code Review Agent
- **Problem:** First-pass code reviews too terse or too verbose; developers needed noise reduction, not more checklist items
- **PTCF:** Persona = senior engineer with constructive, non-blocking style; Task = three-category scope (style guide, OWASP Top 10, test coverage gaps) — Critical and Major issues only; Context = style guide URL, OWASP reference, Python 3.11, hard rule: never block PRs on Minor issues; Format = Markdown findings table (Category, Severity, Line Reference, Recommendation) + overall_verdict (Approve/Request Changes)
- **Key takeaway:** The Task component's explicit scope boundary (Critical and Major only) was the single most impactful design decision. The overall_verdict field integrated the agent into the existing PR workflow with no additional tooling.

---

### Iterating and Evaluating Prompts

Prompt engineering is an iterative, evidence-based discipline — not a one-shot exercise.

**Two core evaluation strategies:**
- **A/B testing** — Run two prompt variants against identical inputs; compare on accuracy, format compliance, response length, or task completion rate. Isolates the effect of a single change.
- **Regression testing** — Maintain a reference suite of canonical inputs with expected outputs. Any prompt revision must pass the full suite without degrading previously passing cases.

**Four-step iteration loop:**

1. **Baseline** — Capture the current prompt version and its performance metrics
2. **Evaluate** — Categorize failure modes: is the agent misidentifying its persona, misinterpreting the task, lacking context, or violating format?
3. **Identify** — Isolate the specific PTCF component responsible; make the smallest targeted change
4. **Revise and version** — Apply the change, label with a version identifier (e.g., v1.2.0), run the regression suite; accept only if the target failure is resolved without introducing new ones

> Treat your prompt history as source code, not a scratch pad. Store prompt versions alongside their evaluation results. Teams that apply software engineering discipline to prompt iteration consistently outperform those that rely on ad hoc editing.
