# Agent Observability and Monitoring
<!-- Covers AWS prescriptive guidance for agentic AI observability, production monitoring patterns (metrics, stacks, OTel instrumentation, alerting), improvement loops (feedback pipelines, experimentation, continuous learning), agent tool accuracy evaluation, and the LangChain model of observability as a learning system. -->

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

## Improvement Loops for Agentic Systems

*Source: "Building Applications with AI Agents" — Michael Albada (O'Reilly, Ch. 11)*

### The Core Principle

In complex multiagent systems, failure is not an anomaly — it's an inevitability. The real test is how well a system learns from those failures and improves over time. Continuous improvement is an interconnected cycle of three pillars:

| Pillar | Purpose | Key Techniques |
|---|---|---|
| **Feedback Pipelines** | Observe, diagnose, and prioritize issues from live interactions | Automated issue detection, RCA, HITL review, prompt/tool refinement |
| **Experimentation** | Validate changes in controlled environments before broad rollout | Shadow deployments, A/B testing, Bayesian Bandits |
| **Continuous Learning** | Embed adaptations into the system permanently or dynamically | In-context learning, offline retraining, DSPy optimization |

> Analogy: Reinforcement learning — agents learn optimal behaviors through iterative interactions, receiving signals from their environment and adapting. The improvement loop applies this principle to production agent systems.

---

### Feedback Pipelines

**What they do:** Continuously monitor interactions, detect failure patterns, cluster issues, and surface actionable insights at scale. Tools: **DSPy** (Stanford NLP — declarative self-improving LM programs), **Microsoft Trace** (generative optimization via general feedback signals, not gradients), **Automatic Prompt Optimization (APO)**.

**Automated Issue Detection triggers:**
- Repeated failures in a particular skill or tool
- Spikes in error rates or response times
- Anomalies in user engagement or satisfaction
- Divergent behavior across agent versions

**Root Cause Analysis (RCA) steps:**
1. **Workflow tracing** — reconstruct the end-to-end chain of decisions, tool invocations, and interactions leading to failure
2. **Fault localization** — isolate the precise component (misinterpreted prompt, wrong skill, malformed tool parameter)
3. **Pattern recognition** — is this isolated or a recurring trend across user cohorts or system states?
4. **Impact assessment** — frequency × severity to prioritize response

> RCA in agentic systems often reveals non-technical root causes: ambiguous task definitions, gaps in training data, evolving user expectations, or misaligned success metrics.

**Human-in-the-Loop (HITL) Review** — required when automated analysis is insufficient:
- Persistent errors with no clear technical explanation
- Anomalies with regulatory or ethical implications
- Failures in high-value or mission-critical tasks
- Conflicting diagnoses from automated tools

Escalation threshold: escalate if model certainty < 0.7, or if consequence × uncertainty exceeds a risk threshold. Aim for <10% of cases escalated to avoid human fatigue. HITL review should involve product managers, data scientists, and UX researchers — not just engineers.

**Prompt Refinement patterns:**
- Rewrite for clarity — eliminate ambiguity, specify expected formats
- Add exemplars — positive and negative examples to anchor reasoning
- Decompose tasks — split complex instructions into sequential prompts
- Expand context — add constraints, background, or error-handling guidance

**DSPy for automated prompt optimization:**
```python
import dspy
dspy.configure(lm=dspy.OpenAI(model="gpt-4o-mini"))

# Define ReAct module, provide annotated trainset, run MIPROv2 optimizer
react = dspy.ReAct("alert -> response", tools=[lookup_threat_intel, query_logs])
tp = dspy.MIPROv2(metric=dspy.evaluate.answer_exact_match, auto="light", num_threads=24)
optimized_react = tp.compile(react, trainset=trainset)
# Result: optimized prompts without manual tweaking
```

**Tool Refinement** addresses: incorrect tool selection, parameter mismatches, gaps in toolset, tool chaining failures. Refinements operate at three levels: internal logic optimization, capability expansion, and integration improvements.

**Prioritization framework for improvements:**
- **Frequency** — how often does it occur?
- **Severity/Impact** — business or user consequence?
- **Feasibility** — effort required to fix?
- **Strategic alignment** — does it enable a key initiative or compliance milestone?
- **Recurrence risk** — systemic vs. isolated failure?

Treat the improvement backlog as a living artifact. Regular triage meetings and cross-team syncs ensure priorities shift with new incidents and strategic changes.

---

### Experimentation

Changes in agentic systems — even minor prompt tweaks — can have far-reaching, unpredictable consequences. Experimentation provides structured, incremental pathways from insight to deployment.

**Shadow Deployments**
Updated agent runs in parallel with production, processing identical inputs but without serving outputs to users. Only production outputs reach users; shadow outputs are logged for comparison.

- Best for: high-impact/high-risk changes (planning workflows, major prompt modifications, external system integrations)
- Measures: tool selection differences, latency, token usage, hallucination frequency
- Challenge: HITL-dependent agents can't interact with users in shadow — use historical replays or synthetic responses

**A/B Testing**
Live traffic split between control (A) and treatment (B) variants. Users interact with one version; quantifiable metrics determine the winner.

Best practices:
- Define clear metrics aligned to the change objective
- Ensure sufficient sample size for statistical significance
- Use "sticky" user assignments to prevent cross-version contamination in stateful agents
- Monitor both short- and long-term effects — quick gains can mask long-term regressions

Tools: LaunchDarkly, Optimizely, or custom dashboards for traffic allocation and metric collection.

**Bayesian Bandits**
Adaptive experimentation that dynamically shifts traffic toward winning variants mid-experiment — no fixed 50/50 split. Models each variant as a "slot machine arm" with unknown odds, using Bayesian updates to reallocate traffic as rewards accumulate.

- **Responsiveness** — shifts allocations in near-real time, reducing opportunity cost
- **Efficiency** — majority of users experience the best configuration as soon as it's identified
- **Scalability** — handles many parameters simultaneously, faster than sequential fixed experiments

When to use: real-time personalization agents, adaptive multiagent workflows, environments where user behavior shifts rapidly. Requires clear reward signals (task success, user satisfaction) and vigilant oversight to prevent optimizing for misleading proxies.

| Method | Best For | Key Limitation |
|---|---|---|
| Shadow Deployment | High-risk changes, no user exposure | Can't handle interactive/HITL flows |
| A/B Testing | Measurable incremental changes | Needs sufficient traffic; stateful agents require careful design |
| Bayesian Bandits | Dynamic, data-rich environments | Requires well-defined reward signals; risk of short-term exploitation |

---

### Continuous Learning

**In-Context Learning** — immediate, session-bound adaptation without model retraining:
- Embed examples, intermediate reasoning steps, or contextual signals into prompts at runtime
- Incorporate real-time user feedback (corrections, clarifications) within the same session
- Requires careful context management: rolling windows, semantic compression, vector-based memory retrieval

Limitations: adaptations are ephemeral — lost when the session ends. Use as a testing ground; successful strategies must be promoted to prompt engineering or offline retraining for permanence.

**Offline Retraining** — periodic, structured embedding of lasting improvements:
1. **Data curation** — gather and label examples from production traces; ensure diversity to avoid bias
2. **Model updates** — few-shot optimization (DSPy) or fine-tuning (LoRA adapters) on held-out data
3. **Validation** — test offline against benchmarks, then via shadow deployment before rollout

Best for: systemic issues identified over time (recurring reasoning misalignments, tool usage patterns, evolving threat vectors). Strengths: changes persist across sessions; scalable for high-volume systems. Limitation: computational cost and risk of overfitting to historical data if retraining is too frequent.

---

### The Full Loop

```
Production Failures / User Signals
        ↓
Feedback Pipelines (detect, cluster, RCA, HITL)
        ↓
Prioritized Improvement Backlog
        ↓
Experimentation (shadow → A/B → bandit)
        ↓
Continuous Learning (in-context → offline retraining)
        ↓
Better Agent → Back to Production
```

> **Org culture note:** Improvement loops are as much organizational as technical. They require alignment across engineering, data science, product, and UX — and a culture that treats every failure as signal, not setback. Documentation is the connective tissue: preserving lessons so teams don't repeat the same mistakes.

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

---

## Observability as a Learning System

*Source: Harrison Chase, LangChain — https://www.langchain.com/blog/agent-observability-needs-feedback-to-power-learning*

---

### The Core Reframe

Most teams treat agent observability as infrastructure for debugging. The more powerful framing: **observability is the raw material for continuous improvement**.

> "Traces are not just records of what happened, and feedback is not just a rating at the end. Together, they are the raw material for improving the system."

And critically:

> "A trace tells you what happened. It does not, by itself, tell you whether what happened was good."

Traces without feedback are incomplete. You cannot systematically answer which trajectories represent success, where problems originate, or whether behavior is actually improving — without pairing traces with structured feedback signals.

---

### Three Levels Where Improvement Happens

| Level | What It Addresses | How to Improve |
|---|---|---|
| **Model Level** | Consistent misclassifications or wrong tool selection | Weight updates via supervised fine-tuning or RL |
| **Harness Level** | Scaffolding failures — ambiguous tool descriptions, missing constraints, suboptimal prompts | Prompt engineering, tool description rewrites, constraint additions |
| **Context Level** | Reasonable decisions made from poor or incomplete information | Retrieval improvements, memory architecture, context compression |

**The diagnostic implication:** Before you retrain a model, check if the failure is at the harness or context level. Most production failures are harness or context failures, not model capability gaps.

---

### Four Feedback Sources

| Source | Signal Type | Reliability | Scale |
|---|---|---|---|
| **Direct** | User ratings, thumbs up/down, corrections | High | Low (requires user action) |
| **Indirect** | Code acceptance rates, ticket reopenings, test passage | Very high (behavioral, not stated) | Medium |
| **LLM-as-Judge** | Scalable evaluation of helpfulness and policy compliance | Medium | High |
| **Deterministic Rules** | Regex patterns, known failure mode checks | High for what they cover | Very high |

**Key insight from Claude Code:** Not all feedback requires model inference. Claude Code uses a frustration-detection regex — cheap rules often capture the most actionable signal at the lowest cost. Start with deterministic rules before reaching for LLM-as-Judge.

---

### What Observability Platforms Must Support

Three non-negotiable capabilities:

1. **Trace Storage** — Complete agent trajectories: model calls, tool invocations, outputs, metadata, errors
2. **Feedback Association** — Direct linkage between feedback signals and the specific traces they evaluate. Feedback in a separate spreadsheet is not observability — it's a spreadsheet.
3. **Feedback Generation** — Automated rules, LLM evaluators, sampling strategies, and the ability to backfill historical traces with new evaluation criteria

If your platform has traces but no structured feedback association, you have logging — not observability.

---

### Practical Takeaways

1. **Instrument for learning, not just debugging** — capture traces with the explicit goal of identifying training examples and failure patterns
2. **Layer your feedback sources** — deterministic rules first, then indirect signals, then LLM-as-Judge, then direct user feedback
3. **Attribute failures to the right level** — model, harness, or context — before deciding how to fix them
4. **Close the loop** — surface feedback back to the teams and systems that can act on it (prompt engineers, ML teams, retrieval engineers)
5. **Backfill historical traces** — when you develop new evaluators, run them against historical data to detect when regressions were introduced
