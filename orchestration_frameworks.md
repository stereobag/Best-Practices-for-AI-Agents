# Orchestration Frameworks and Agent Harness Evaluation
<!-- Covers orchestration framework comparisons (LangGraph, CrewAI, PydanticAI, Claude Agent Teams, LangChain Open SWE), the anatomy of an agent harness, and detailed evaluations of all major agent frameworks including LangChain, LangGraph, LlamaIndex, AutoGPT, CrewAI, AutoGen, vector databases, tool integration patterns, cloud platforms, and the build vs. integrate decision guide. -->

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

## Agent Harness Frameworks — Detailed Evaluation

---

### The Anatomy of an Agent Harness

*Source: Harrison Chase, LangChain — https://www.langchain.com/blog/the-anatomy-of-an-agent-harness*

**Agent = Model + Harness**

> "The model contains the intelligence and the harness is the system that makes that intelligence useful."

A harness is every piece of code, configuration, and execution logic that isn't the model itself. Raw models cannot maintain persistent state, execute code, access real-time knowledge, or set up environments. The harness bridges that gap.

**Harness components:**
- System prompts
- Tools, skills, and MCPs with their descriptions
- Bundled infrastructure (filesystem, sandbox, browser)
- Orchestration logic (subagent spawning, handoffs, model routing)
- Hooks and middleware for deterministic execution

---

### Core Harness Primitives

| Primitive | Purpose | Key Detail |
|---|---|---|
| **Filesystem** | Durable workspace for data, code, docs | Git integration enables version control and multi-agent collaboration |
| **Bash / Code Execution** | General-purpose problem solving | Instead of constraining agents to pre-built tools, let the model write and execute code to solve novel problems |
| **Sandboxes** | Safe isolated execution | Configurable resource limits and network restrictions; required before giving agents Bash access in production |
| **Memory and Search** | Continual learning across sessions | Memory files (e.g. AGENTS.md, CLAUDE.md) persist knowledge; web search and MCP fill gaps beyond training cutoffs |
| **Context Management** | Handle context window limits | Three strategies: compaction (summarize + offload), tool call offloading (store large outputs to filesystem, keep summaries in context), skills (progressive tool disclosure to prevent startup overload) |
| **Planning and Self-Verification** | Ground solutions in outcomes | Agents decompose goals into steps, run tests, feed results back — creating a self-correcting loop |

---

### Long-Horizon Execution: Ralph Loops

For work that spans multiple context windows, harnesses use **Ralph Loops**:

```
Agent approaches context limit
        ↓
Harness intercepts model exit
        ↓
Reinjects prompt with clean context window
        ↓
Agent continues from durable state (filesystem / git)
        ↓
Verification loop runs tests → feeds results back
```

This pattern enables autonomous execution of tasks that would otherwise exceed a single context window — critical for real-world engineering tasks.

---

### Model-Harness Co-Evolution

Post-training happens with models and harnesses in the loop. Useful harness primitives influence subsequent model training — models learn to expect and use harness capabilities. Side effects:

- **Overfitting risk:** Models can overfit to a specific harness design; swapping harnesses can significantly change benchmark performance
- **Migration cost:** As models improve, some harness responsibilities migrate into model weights — harness code that was essential last year may become redundant
- **Future-proofing:** Build harnesses around stable primitives (filesystem, bash, memory, sandboxes) rather than complex orchestration logic that models will eventually internalize

---

*Source: "30 Agents Every AI Engineer Must Build" — Packt Publishing, Ch. 2*

### Framework Comparison at a Glance

| Framework | Primary Strength | Key Limitation | Ideal Use Case |
|-----------|-----------------|----------------|----------------|
| **LangChain** | Extensive tooling ecosystem, rapid prototyping | Can be verbose; abstraction layers add complexity | General-purpose agents, quick PoCs |
| **LlamaIndex** | Deep retrieval / RAG specialization | Less flexible for non-retrieval workflows | Knowledge-intensive agents, document Q&A |
| **AutoGPT** | Autonomous task decomposition with minimal input | Unpredictable execution paths, hard to debug | Autonomous exploratory tasks |
| **CrewAI** | Clean role-based multi-agent collaboration | Newer ecosystem, fewer integrations | Structured multi-agent workflows |
| **LangGraph** | Fine-grained workflow control, stateful execution | Higher implementation complexity | Production pipelines requiring reliability |
| **AutoGen** | Conversational multi-agent programming | Conversation management overhead | Research workflows, debate/critique patterns |

---

### LangChain

LangChain is the most widely adopted agent framework. Its core abstractions:

- **Chains** — sequences of calls to models, tools, or data sources; composable building blocks
- **Agents** — LLM-driven decision-makers that select which tools to invoke at each step
- **Tools** — encapsulated functions (web search, calculators, code execution, API calls) with a name, description, and callable interface
- **Memory** — conversation history persistence (in-memory, Redis, DynamoDB) enabling multi-turn context
- **Retrievers** — abstraction over vector stores for document retrieval

**Key design pattern — Tool abstraction:**
```python
from langchain.tools import Tool

search_tool = Tool(
    name="WebSearch",
    description="Search the web for current information",
    func=search_function
)
```

**Strengths:** Large ecosystem, well-documented, fastest path from idea to working prototype.

**Limitations:** Abstraction layers can obscure what's happening; complex chains become difficult to debug; verbose for simple tasks.

**Best for:** General-purpose agents, integrating diverse tools, rapid PoC development.

---

### LangGraph

LangGraph extends LangChain with a graph-based execution engine for stateful, multi-step workflows.

**Core concepts:**
- **Nodes** — individual processing steps (model calls, tool calls, conditional logic)
- **Edges** — transitions between nodes; can be conditional based on state
- **State** — shared data structure passed between nodes, updated at each step
- **Conditional branching** — routes execution based on state values (e.g., "if confidence < 0.8, route to human review")

**Key design pattern:**
```python
from langgraph.graph import StateGraph

workflow = StateGraph(AgentState)
workflow.add_node("reason", reasoning_step)
workflow.add_node("act", action_step)
workflow.add_conditional_edges("reason", should_continue, {
    "continue": "act",
    "end": END
})
```

**Strengths:** Explicit control flow, deterministic behavior, built-in state persistence, supports human-in-the-loop checkpoints.

**Limitations:** More boilerplate than LangChain; requires upfront graph design.

**Best for:** Production pipelines requiring reliability, complex conditional workflows, systems needing audit trails.

---

### LlamaIndex

LlamaIndex is purpose-built for retrieval-augmented generation (RAG) and knowledge-intensive agents.

**Core pipeline components:**
1. **Index** — ingests and structures documents (vector, tree, keyword, knowledge graph)
2. **Query Engine** — processes questions against the index
3. **Response Synthesizer** — combines retrieved chunks into coherent answers

**RAG pipeline pattern:**
```
[Documents] → [Chunking] → [Embedding] → [Index]
                                              ↓
[User Query] → [Embedding] → [Retrieval] → [Synthesizer] → [Response]
```

**Chunking strategies supported:** Fixed-size, sentence-window, semantic, hierarchical

**Strengths:** Best-in-class retrieval quality, rich index types, tight integration with vector stores, built-in evaluation for retrieval accuracy.

**Limitations:** Less suitable for non-retrieval agent workflows; smaller general tool ecosystem.

**Best for:** Document Q&A, enterprise knowledge bases, research assistants, any use case requiring high-quality retrieval.

---

### AutoGPT

AutoGPT pioneered the autonomous agent paradigm — given a goal, the agent self-decomposes tasks, executes steps, and iterates without human prompting between steps.

**Execution model:**
1. Goal → high-level task decomposition
2. Per-task: reason about next action → select tool → execute → observe result → update plan
3. Loop until goal satisfied or resource limit reached

**Strengths:** Minimal human input required; handles open-ended goals.

**Limitations:** Execution paths are hard to predict and debug; prone to loops or off-track reasoning; resource consumption can be uncapped.

**Best for:** Exploratory research tasks, automated data gathering, situations where the full task structure is unknown upfront.

---

### CrewAI

CrewAI models multi-agent collaboration as a crew of specialized workers with defined roles, tasks, and tools.

**Core abstractions:**
- **Agent** — has a role (e.g., "Senior Researcher"), goal, and backstory that shape its behavior
- **Task** — discrete unit of work assigned to an agent with expected output
- **Crew** — orchestrates agents and tasks; handles delegation and result aggregation
- **Process** — sequential or hierarchical execution of the task graph

**Example crew:**
```python
from crewai import Agent, Task, Crew

researcher = Agent(role="Senior Researcher", goal="Find relevant papers", ...)
writer = Agent(role="Technical Writer", goal="Summarize findings clearly", ...)

research_task = Task(description="Research LLM memory techniques", agent=researcher)
write_task = Task(description="Write a 500-word summary", agent=writer)

crew = Crew(agents=[researcher, writer], tasks=[research_task, write_task])
crew.kickoff()
```

**Strengths:** Clean role-based design makes multi-agent systems intuitive to build and reason about; good for structured workflows with defined handoffs.

**Limitations:** Newer ecosystem with fewer third-party integrations; less fine-grained execution control than LangGraph.

**Best for:** Content pipelines, research summarization, any multi-agent workflow where distinct roles and responsibilities are well-defined.

---

### AutoGen (Microsoft)

AutoGen implements a conversational programming paradigm — agents interact with each other through structured conversations to accomplish tasks.

**Core concepts:**
- **ConversableAgent** — base class; can send/receive messages and call tools
- **AssistantAgent** — LLM-backed agent that generates responses and plans
- **UserProxyAgent** — executes code, runs tools, represents human feedback channel
- **GroupChat** — coordinates multi-agent conversations with a manager directing speaker selection

**Strengths:** Natural fit for tasks that benefit from debate, critique, and refinement (code review, research synthesis, adversarial evaluation); flexible conversation topologies.

**Limitations:** Conversation management adds overhead; harder to guarantee deterministic execution paths.

**Best for:** Research workflows, code generation with self-review, scenarios where multiple perspectives improve output quality.

---

### Vector Database Landscape

Vector databases are the retrieval backbone for knowledge-intensive agents. Key players in 2026:

| Database | Deployment | Scale | Differentiator |
|----------|-----------|-------|----------------|
| **Pinecone** | Managed SaaS | 100M+ vectors | Simplest ops; best for teams prioritizing time-to-production |
| **Weaviate** | Self-hosted / Cloud | Large | Hybrid search (vector + keyword); built-in ML modules |
| **Chroma** | Embedded / Self-hosted | Small–Medium | Zero-config local dev; ideal for prototyping |
| **Milvus** | Self-hosted / Cloud | Billion-scale | Purpose-built for extreme scale; rich indexing algorithms |
| **Qdrant** | Self-hosted / Cloud | Large | Payload filtering, on-disk indexes, Rust performance |

**Selection guide:**
- **Prototyping/local dev:** Chroma — zero setup, runs in-process
- **Production managed:** Pinecone — no infrastructure management
- **Production self-hosted:** Milvus (billion+ vectors) or Qdrant (strong filtering needs)
- **Hybrid search requirements:** Weaviate

**RAG pipeline integration pattern:**
```python
# Ingest
embeddings = embedding_model.embed(documents)
vector_db.upsert(ids, embeddings, metadata)

# Query
query_embedding = embedding_model.embed(query)
results = vector_db.query(query_embedding, top_k=5)
context = "\n".join([r.text for r in results])
response = llm.complete(f"Context: {context}\n\nQuestion: {query}")
```

---

### Tool Integration Patterns

#### LangChain Tool Abstraction

The Tool abstraction decouples capability definition from agent reasoning:

```python
from langchain.tools import Tool, StructuredTool
from pydantic import BaseModel

class SearchInput(BaseModel):
    query: str
    max_results: int = 5

search_tool = StructuredTool.from_function(
    func=search_function,
    name="WebSearch",
    description="Search the web. Use when you need current information.",
    args_schema=SearchInput
)
```

Key principles:
- **Description quality is critical** — the LLM uses the description to decide when to invoke the tool
- **Schema validation** — StructuredTool enforces parameter types before execution
- **Error handling** — tools should return error strings rather than raise exceptions (keeps agent reasoning intact)

#### OpenAI Function Calling

Framework-agnostic tool invocation through structured function schemas:

```python
tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current weather for a location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string", "description": "City name"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["location"]
        }
    }
}]
```

The model returns a structured `tool_calls` response; the application executes the function and returns the result as a tool message. This pattern is now supported by Claude, GPT-4, Gemini, and most major models.

---

### Cloud-Native Agent Platforms

#### AWS Bedrock Agents

Fully managed agent runtime on AWS. Key capabilities:
- **Knowledge Bases** — managed RAG pipeline (S3 → chunking → embedding → OpenSearch Serverless)
- **Action Groups** — Lambda-backed tools defined via OpenAPI schema
- **Guardrails** — content filtering, PII detection, topic denial built into the runtime
- **Inline agents** — programmatic agent creation without pre-configuration

**Best for:** Teams already on AWS; production agents requiring guardrails and audit logging without infrastructure management.

#### Azure AI Foundry (formerly Azure AI Studio)

Microsoft's unified platform for enterprise AI agents:
- **Prompt Flow** — visual DAG editor for multi-step agent workflows
- **Azure AI Agent Service** — managed agent runtime with built-in tool support (Bing, Code Interpreter, Azure Functions)
- **Responsible AI dashboard** — fairness, interpretability, error analysis built in
- **Entra ID integration** — enterprise identity and access management

**Best for:** Microsoft-ecosystem enterprises; teams requiring Responsible AI tooling and Azure compliance certifications.

#### Google Vertex AI — Agent Development Kit (ADK) + Agent Engine

- **ADK** — open-source Python framework for building agents; integrates with Gemini models and Google tools (Search, Code Execution, Grounding)
- **Agent Engine** — managed runtime for deploying ADK agents at scale; handles session management, scaling, and monitoring
- **A2A protocol** — Google's Agent-to-Agent protocol (now Linux Foundation) for inter-agent communication

**Best for:** Teams using Gemini models; agents requiring Google Search grounding; organizations interested in A2A for multi-agent coordination.

---

### Build vs. Integrate Decision Guide

| Scenario | Recommendation |
|----------|---------------|
| PoC / internal tool | LangChain or CrewAI — fastest to working prototype |
| Production pipeline with complex branching | LangGraph — explicit control flow, state persistence |
| Document Q&A / knowledge retrieval | LlamaIndex — purpose-built retrieval quality |
| Multi-agent with role clarity | CrewAI — clean abstractions for agent roles |
| Research/adversarial evaluation pattern | AutoGen — conversational paradigm fits multi-perspective tasks |
| AWS-native production | Bedrock Agents — managed runtime, guardrails, no infra |
| Azure enterprise | Azure AI Foundry — compliance, Responsible AI, Entra ID |
| Google/Gemini-centric | Vertex AI ADK + Agent Engine |
| Billion-scale vector retrieval | Milvus + LlamaIndex |
| Fast local dev / prototyping retrieval | Chroma + LangChain |

> **Key insight:** Framework choice is primarily a build-vs-buy decision on orchestration complexity. LangChain and LlamaIndex dominate prototyping; LangGraph and cloud platforms (Bedrock, Foundry, Vertex) dominate production. Vector database choice is driven by scale and operational model, not framework compatibility — all major frameworks support all major vector stores.
