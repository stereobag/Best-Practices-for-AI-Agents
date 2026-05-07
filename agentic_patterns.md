# Agentic Patterns: Five Workflow Patterns for Production AI

*Source: "Stop Building AI Agents — Use These Instead" — DecodingAI / decodingai.com*

---

## The Core Principle

> "Most use cases don't need agents. They need better workflows." — Hugo Bowne-Anderson

**The decision ladder:**
1. Start with a single prompt. If it works, stop.
2. If it doesn't, try these five workflow patterns.
3. Only if all patterns fail, consider a full agent.

Five patterns solve ~95% of production AI problems. Full agents add autonomy, but also add unpredictability, cost, and debugging complexity. Reach for patterns first.

---

## Pattern 1: Prompt Chaining

**What it is:** Connect multiple LLM calls sequentially — the output of one step becomes the input for the next.

**When to use:**
- A complex task naturally breaks into focused, ordered sub-tasks
- You need to isolate errors to a specific component
- Different steps benefit from different models or prompts

```python
def writing_workflow(research_and_intent: str) -> dict:
    media_assets = create_media_assets(research_and_intent)
    article_draft = generate_article(research_and_intent, media_assets)
    title = generate_title(article_draft)
    seo_metadata = generate_seo(article_draft, title)

    return {
        "title": title,
        "article": article_draft,
        "seo": seo_metadata,
    }
```

**Tradeoffs:**

| Pro | Con |
|---|---|
| Enhanced modularity and accuracy | Instructions can lose meaning across steps |
| Easier debugging — failures localize | Context loss between prompts |
| Swap models per step independently | Increased cost and latency |
| | Chain failures cascade |

---

## Pattern 2: Parallelization

**What it is:** Run independent steps concurrently. Steps that don't depend on each other's outputs can execute simultaneously.

**When to use:**
- Uniform, independent sub-tasks (e.g., generating 5 media assets from one input)
- Multiple data sources requiring parallel extraction
- Any step that is a pure function of the same shared input

```python
import asyncio

async def parallel_media_generation(research_and_intent, max_concurrent=3):
    asset_types = ["diagram", "image_1", "image_2", "image_3", "image_4"]
    semaphore = asyncio.Semaphore(max_concurrent)

    async def generate_with_limit(asset_type):
        async with semaphore:
            return await generate_media_asset(asset_type, research_and_intent)

    tasks = [generate_with_limit(atype) for atype in asset_types]
    return await asyncio.gather(*tasks)
```

**Key implementation concerns:**
- **Rate limits:** Use a semaphore to cap concurrent calls against API RPM quotas
- **Retry strategy:** Implement exponential backoff on transient failures
- **Race conditions:** Tasks must be truly independent — no shared mutable state

---

## Pattern 3: Routing

**What it is:** Direct the workflow down different paths based on input classification. An LLM (or simple classifier) acts as the router.

**When to use:**
- Inputs fall into distinct categories that require different handling
- A single prompt trying to cover multiple use cases degrades quality for all of them
- Customer support, intent detection, content triage

```python
def routing_workflow(user_intent):
    media_type = classify_media_intent(user_intent)  # small/fast model here

    if media_type == "diagram":
        return generate_diagram(user_intent)
    elif media_type == "image":
        return generate_image(user_intent)
    elif media_type == "video":
        return generate_video(user_intent)
    else:
        return handle_default(user_intent)  # always include a catch-all
```

**Cost optimization:** For classification-only routing, use a smaller, faster, cheaper model. The router doesn't need the same capability as the downstream handlers.

**Rule:** Always include a default/catch-all route. Unexpected inputs will arrive in production.

---

## Pattern 4: Orchestrator-Worker

**What it is:** A central LLM (orchestrator) dynamically decomposes a complex task into sub-tasks at runtime and delegates them to specialized workers, which run in parallel.

**How it differs from parallelization:** The number and type of sub-tasks are determined at inference time by the orchestrator, not hardcoded. The orchestrator decides *what* work to dispatch; workers execute it.

**Analogy:** Map-Reduce from data engineering — orchestrator = map phase, worker pool = reduce phase.

```python
from concurrent.futures import ThreadPoolExecutor

TOOLS = {
    "generate_diagram": lambda prompt: f"Diagram: {prompt}",
    "generate_image":   lambda prompt: f"Image: {prompt}",
    "generate_video":   lambda prompt: f"Video: {prompt}",
}

def orchestrator(user_intent):
    # Returns a list of tool calls with names + arguments
    return LLM.call(user_intent=user_intent, tools=TOOLS)

def worker(tool_call):
    return TOOLS[tool_call["tool"]](**tool_call["arguments"])

def orchestrator_worker_workflow(user_intent):
    tool_calls = orchestrator(user_intent)
    with ThreadPoolExecutor() as executor:
        results = list(executor.map(worker, tool_calls))
    return results
```

**Implementation tip:** Express the set of possible jobs as structured tool definitions. The orchestrator outputs tool calls with arguments; the executor dispatches them in parallel.

**Primary failure mode:** Orchestrator creates wrong jobs, incorrect arguments, or the wrong quantity of tasks. Validate orchestrator output before dispatch.

---

## Pattern 5: Evaluator-Optimizer

**What it is:** A feedback loop — a generator LLM produces output, an evaluator LLM scores and critiques it, the generator refines based on feedback. Repeats until quality threshold or max iterations.

**When to use:**
- Output quality matters more than latency
- You need automatic refinement without human review
- Tasks where first-pass output is reliably improvable with feedback

**Closest to agent-like behavior while remaining a structured workflow.**

```python
def generator(prompt, feedback=None):
    if feedback:
        prompt += f"\nIncorporate this feedback: {feedback}"
    return llm_call(prompt)

def evaluator(article_draft):
    evaluation = llm_evaluator_call(article_draft)
    return evaluation["score"], evaluation["feedback"]

def evaluator_optimizer_workflow(initial_prompt):
    max_iterations = 3
    score_threshold = 0.8

    article = generator(initial_prompt)

    for i in range(max_iterations):
        score, feedback = evaluator(article)

        if score >= score_threshold:
            return article  # quality threshold met

        article = generator(initial_prompt, feedback)

    return article  # max iterations reached — return best version
```

**Primary failure mode:** Infinite optimization loops. Always set both a score threshold *and* a maximum iteration cap — never rely on threshold alone.

**Advanced variant:** Multiple specialized evaluators (logical correctness, readability, syntax compliance) each produce a separate score and critique, giving the generator richer, targeted feedback.

---

## Pattern Comparison

| Pattern | Dynamic? | Parallelism | Best For | Main Risk |
|---|---|---|---|---|
| **Prompt Chaining** | No | No | Ordered, dependent steps | Context loss; cascade failures |
| **Parallelization** | No | Yes | Independent uniform tasks | Rate limits; race conditions |
| **Routing** | Classifier-driven | No | Multi-category inputs | Missing catch-all; misclassification |
| **Orchestrator-Worker** | Yes (runtime) | Yes | Complex dynamic decomposition | Wrong task dispatch from orchestrator |
| **Evaluator-Optimizer** | No | No | Quality-critical generation | Infinite loops |

---

## When to Actually Use a Full Agent

Reach for a full agent only when all five patterns have failed to meet requirements. Agents add:
- Loop autonomy (the model decides when to stop)
- Tool selection at runtime
- Multi-step replanning on failure

And with that comes: higher cost, harder debugging, less predictable behavior, and longer evaluation cycles.

**The test:** If you can express the workflow as a fixed graph of calls — even with dynamic node count (orchestrator-worker) or feedback loops (evaluator-optimizer) — you don't need an agent.

---

## Connection to Other Patterns in This Repo

- **Evaluator-Optimizer** is the workflow implementation of the LLM-as-Judge pattern (see `llm_as_a_judge.md`) — structured outputs (see `structured_outputs.md`) are how the evaluator's score and feedback are reliably extracted
- **Orchestrator-Worker** maps to the Hierarchical multi-agent architecture (see `agent_types_and_architectures.md`)
- **Routing** is the foundation of the Router multi-agent selection pattern from LangChain (see `agent_types_and_architectures.md`)
- **Prompt Chaining** corresponds to Anthropic's "prompt chaining" composable workflow pattern
