# Agent Memory Management

*Source: "How Does Memory for AI Agents Work?" — DecodingAI / decodingai.com*

---

## Why Memory Matters

LLM knowledge is frozen at training time. Without memory systems, every agent interaction starts from scratch — no personalization, no continuity, no learning. Memory systems are what transform a stateless LLM into an agent that can maintain context, update preferences, and build on prior interactions.

**The core principle:** Agents don't learn by updating weights. They "learn" by engineering what goes into the context window.

---

## The Four Memory Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     AGENT REASONING                         │
│                                                             │
│  Internal Knowledge  ←→  Context Window (the model's RAM)  │
│  (frozen in weights)       ↑           ↑                    │
│                            │           │                    │
│                    Short-Term       Long-Term               │
│                    Memory           Memory                  │
│                    (active RAM)     (persistent disk)       │
└─────────────────────────────────────────────────────────────┘
```

### Layer 1: Internal Knowledge
- Stored in model weights; no context window space consumed
- Contains general world knowledge up to training cutoff
- **Limitation:** Frozen at training time — cannot be updated post-deployment

### Layer 2: Context Window
- The only "reality" the model sees during inference
- Functions as the LLM's RAM — the information slice passed during a specific call
- Everything the agent knows *right now* must fit here
- Context engineering is the mechanism through which agents appear to learn

### Layer 3: Short-Term Memory
- Active working memory for the current session
- Contains: active context window, recent interactions, conversation history, retrieved long-term information
- Volatile and fast; creates the sensation of "learning" within a session
- Lost between sessions unless explicitly persisted

### Layer 4: Long-Term Memory
- External persistent storage (the agent's disk)
- Enables saving and retrieval across sessions
- Provides personalization and continuity that context window alone cannot sustain
- Retrieved into short-term memory when needed — not constantly in the context window

---

## Long-Term Memory: Three Subtypes

### Semantic Memory — Facts & Knowledge
The agent's encyclopedia. Stores independent knowledge pieces or structured attributes.

**What it holds:** Discrete facts about users, entities, or the domain. Examples:
- "User prefers concise responses"
- "User's dog is named George"
- "User's budget constraint is $50K"

**Why it exists:** Reliable fact retrieval without scanning noisy conversation history. Supports precise queries like "What is the user's brother's job?"

---

### Episodic Memory — Experiences & History
The agent's personal diary. Records past interactions with timestamps.

**What it holds:** What happened and when. Dialogue summaries, interaction outcomes, decision traces.

**Why it exists:** Provides nuanced context for future interactions and maintains conversation continuity. Enables temporal queries like "What did we discuss last week?" or "Why did I reject that option previously?"

**Implementation note:** Raw conversation logs are compressed into summaries for efficient retrieval — storing full dialogues verbatim is expensive and noisy.

---

### Procedural Memory — Skills & Workflows
The agent's muscle memory. Encodes multi-step workflows and learned skills.

**What it holds:** Reusable sequences of actions. Often surfaced as system prompt instructions or tool definitions.

**Example workflow stored:**
```
Query DB → Summarize results → Draft email → Send
```

**Why it exists:** Makes behavior reliable and predictable. An agent that has learned the "monthly report" workflow doesn't need to re-derive it from first principles each time.

---

## Storage Approaches: Tradeoffs

| Approach | Pros | Cons | Best For |
|---|---|---|---|
| **Raw Strings** | Simple setup; preserves emotional tone and linguistic nuance | Imprecise retrieval; contradictions accumulate; difficult updates | Quick prototypes, low-volume conversational context |
| **Entities (JSON / Structured)** | Precise field-level filtering; easy updates via field overwriting | Requires upfront schema; rigid; data loss for information that doesn't fit schema | Semantic memory — user profiles, structured facts |
| **Knowledge Graphs** | Excels at complex relationships; superior contextual and temporal awareness; auditable retrieval paths | Highest complexity and cost; graph traversals add latency; hard to convert unstructured text | Multi-entity relationship tracking; reasoning over time |

**Starting advice:** Start with raw strings or JSON entities. Graduate to knowledge graphs only when relational complexity justifies the overhead.

---

## The Memory Cycle: 10 Steps

```
1. User Input          → Triggers the system
2. Ingestion           → Populates long-term memory via pipelines or APIs
3. Retrieval           → Pulls relevant data into short-term memory using search/vector tools
4. Short-Term Assembly → Combines: facts + user input + LLM output + tool schemas
5. Context Engineering → Slices short-term memory to fit within the context window
6. Inference           → Passes assembled context to LLM for generation
7. Loop                → Adds LLM output back into short-term memory
8. Update (Internal)   → Modifies long-term memory with new user facts and preferences
9. Update (External)   → Refreshes long-term memory from external data pipelines
10. Persistence        → Saves short-term memory state across sessions
```

**Key insight:** Steps 5 and 8 are where most agent memory engineering happens. Step 5 (context engineering) determines what the model can reason about right now. Step 8 (internal update) determines what the agent will remember next time.

---

## RAG vs. CAG

**RAG (Retrieval-Augmented Generation):** Retrieve relevant chunks from a large external store and inject them into context at inference time.

**CAG (Context-Augmented Generation):** For agents with bounded, well-known data, pre-engineer the context window with smart curation rather than running retrieval pipelines.

**When CAG wins:** Vertical agents with a finite, well-defined knowledge domain. CAG is faster, cheaper, and more reliable than complex retrieval pipelines when the data boundary is known. RAG scales better when the knowledge base is large, dynamic, or open-ended.

---

## Design Principles

**1. Match memory subtype to query type**
- "What is X?" → Semantic memory
- "What happened when?" → Episodic memory
- "How do I do Y?" → Procedural memory

**2. Keep long-term memory out of the context window by default**
Long-term memory is retrieved on demand, not pre-loaded. Preloading everything defeats the purpose — the context window is finite.

**3. Separate retrieval from reasoning**
Retrieval populates short-term memory; the model reasons over short-term memory. These are different steps in the cycle (steps 3 and 6), not the same operation.

**4. Compress episodic memory before storing**
Store summaries of interactions, not raw transcripts. Raw conversation logs accumulate quickly and produce noisy retrieval results.

**5. Start simple and evolve**
No single storage method suits all use cases. Raw strings → JSON entities → knowledge graphs is a natural progression as complexity grows. Don't architect for knowledge graphs on day one.

**6. Persist short-term memory explicitly**
Short-term memory is volatile by default. If session continuity matters, step 10 (persistence) must be a first-class concern in your architecture — it doesn't happen automatically.

---

## Memory in the Context of Claude Code

The paper "Dive Into Claude Code" (arXiv:2604.14228) documents how Claude Code implements a four-level memory hierarchy (`dive_into_claude_code_architecture.md`):

| Memory Type | Claude Code Implementation | Corresponds To |
|---|---|---|
| Internal knowledge | Model weights | Internal Knowledge layer |
| CLAUDE.md hierarchy | 4-level markdown files (managed → user → project → local) | Semantic + Procedural memory |
| Auto memory | Entries Claude writes during conversations | Episodic memory |
| Session transcripts | Append-only JSONL files | Episodic memory |
| Compact summaries | Model-generated summaries of compressed history | Episodic memory (compressed) |

**Critical design choice in Claude Code:** CLAUDE.md content is delivered as a *user message* (probabilistic compliance), not a system prompt. Permission rules provide deterministic enforcement — a deliberate separation between guidance and enforcement.
