# LLM-as-a-Judge: A Practical Guide

*Source: "Mastering LLM-as-a-Judge" — Galileo / Pratik Bhavsar (Mastering GenAI Series)*

---

## What It Is

LLM-as-a-Judge uses a powerful LLM to evaluate the quality of outputs from other LLMs (or itself). The methodology prompts a judge model to assess outputs against defined criteria, producing a score, reasoning, and specific feedback.

**Why it exists:** Statistical metrics like BLEU/ROUGE miss qualitative aspects — empathy, helpfulness, cultural nuance, factual grounding. Human evaluation doesn't scale. LLM-as-a-Judge sits in the middle: nuanced evaluation at machine scale.

**Core equation:** `LLM Judge → Quality Score + Reasoning + Specific Feedback`

---

## When to Use It

Use LLM-as-a-Judge when:

| Signal | Description |
|---|---|
| **Subjective output** | Writing style, tone, creativity, empathy — traditional metrics fail |
| **Complex context required** | Evaluation needs understanding of nuance, intent, or domain |
| **Scale** | Thousands of responses to evaluate; human review is impractical |
| **Consistency needed** | Same criteria must apply across many samples |

Skip it when: deterministic checks (regex, schema validation, unit tests) can answer the question cheaper.

---

## Three Scoring Approaches

### 1. Single Output Scoring — Without Reference
The judge scores output against predefined criteria on a discrete scale. Each scale value must be clearly defined.

**Example criteria (1–3):**
- 1: Unprofessional or dismissive
- 2: Professional but incomplete resolution
- 3: Professional, empathetic, and provides clear resolution

**Best for:** Straightforward evaluations where quality can be assessed independently.

---

### 2. Single Output Scoring — With Reference
Builds on the first approach by providing reference material (reasoning steps, expected answers, domain knowledge) to anchor the judgment.

**Best for:** Factual accuracy checks, RAG output grounding evaluation, domain-specific compliance.

---

### 3. Pairwise Comparison
The judge is presented with two outputs and selects the superior one based on specified criteria. Avoids absolute scoring difficulties — the model only makes a relative judgment.

**Best for:** Determining which of two responses is more relevant, comprehensive, or on-tone. A/B evaluation of prompt changes.

| Approach | Ground Truth Needed | Best For | Key Limitation |
|---|---|---|---|
| Single (no reference) | No | Style, tone, safety | Scale value calibration |
| Single (with reference) | Yes | Factual accuracy, grounding | Reference quality matters |
| Pairwise | No | Relative quality ranking | Doesn't give absolute scores |

---

## Biases in LLM-as-a-Judge (and How to Mitigate)

LLMs are trained on human-annotated data — they inherit human biases and add their own.

| Bias | What It Is | Example | Mitigation |
|---|---|---|---|
| **Nepotism** | LLM favors its own generated content | GPT-4 rates its own response higher than Claude's for the same quality | Use a different model family as judge than the generator |
| **Verbosity** | Equates length with quality | Lengthy, redundant explanation rated higher than concise, accurate one | Explicitly instruct judge to value conciseness; include length as a negative criterion |
| **Authority** | Assigns credibility to authority signals | "According to Harvard researchers..." scores higher regardless of accuracy | Strip authority markers from evaluated text before judging |
| **Positional** | 35% of judgments change based on answer order | Output A wins just because it appears first | Swap positions, run pairwise twice and average |
| **Self-preference** | Models favor own outputs by 10–25% | GPT-4 rates GPT-4 outputs higher than equally-good Claude outputs | Use a different model family for judge vs generator |

---

## ChainPoll — Multi-Judge Voting

Single LLM judge AUROC: 66–68%. Fix: run 5 judges in parallel on the same prompt.

**Settings:** Temperature 0 · 5 parallel instances · Score = (# Fail) / 5

**Example:** 3 judges return Fail, 2 return Pass → hallucination risk score = 0.60

| Method | AUROC | vs ChainPoll |
|---|---|---|
| **ChainPoll (5 judges)** | **0.781** | — |
| SelfCheck-Bert | 0.673 | -14% |
| SelfCheck-NGram | 0.644 | -18% |
| G-Eval | 0.579 | -26% |
| GPTScore | 0.524 | -33% |

Cost: $0.015/eval (5× gpt-3.5-turbo) vs $0.060 for GPT-4. 4× cheaper and more accurate.

**F1 benchmarks for judge quality:**

| Score | Rating |
|---|---|
| ≥ 0.95 | Outstanding |
| ≥ 0.85 | Excellent |
| 0.70–0.85 | Substantial |
| < 0.50 | Poor |

---

## Best Practices for Building Your LLM Judge

### 1. Mitigate Evaluation Biases
- Use a different model family as judge than generator
- Randomize position in pairwise comparisons
- Run calibration against known-good examples to detect systematic bias before deployment

### 2. Enforce Reasoning
Require the judge to produce reasoning before its score. Chain-of-thought reasoning improves consistency and makes failures auditable.

```
Bad:  "Score: 2"
Good: "The response addresses the customer's question directly (✓) but fails to 
       acknowledge the emotional context of the complaint (✗) and offers no 
       follow-up path (✗). Score: 2"
```

### 3. Break Down Criteria Into Components
Don't ask the judge to score "overall quality" — decompose into specific dimensions:
- Factual accuracy
- Tone appropriateness
- Task completion
- Safety/compliance
- Conciseness

Score each separately, then aggregate. This makes failures actionable.

### 4. Align Evaluations With User Objectives
The judge should optimize for what users actually care about, not what's easy to measure. Map evaluation criteria back to business outcomes (resolution rate, customer satisfaction, task completion).

### 5. Utilize Few-Shot Learning
Embed positive and negative examples in the judge prompt. This anchors the scale and reduces ambiguity about what each score level means.

```
Example of Score 3 (exemplary):
  Response: "I understand this is frustrating. Your order was delayed due to a 
  carrier issue. Here's your tracking link and a $10 credit for the inconvenience."
  
Example of Score 1 (poor):
  Response: "Check the tracking page."
```

### 6. Incorporate Adversarial Testing
Include known-bad examples (hallucinations, off-topic responses, policy violations) in your validation set. A judge that can't reliably catch known failures shouldn't be trusted in production.

### 7. Implement Iterative Refinement
Judge quality degrades with prompt drift. Establish a regression suite of canonical examples with expected scores. Any prompt change must pass the full suite. Version your judge prompts the same way you version code.

---

## Five Key Components of an LLM-as-a-Judge System

1. **Evaluation criteria** — specific, measurable dimensions aligned to user objectives
2. **Scoring rubric** — discrete scale with clearly defined values and examples
3. **Judge prompt** — includes criteria, rubric, reasoning requirement, and few-shot examples
4. **Validation pipeline** — calibration against known examples; bias detection
5. **Feedback loop** — surfacing judge outputs back to prompt engineers and ML teams

---

## Using Small Language Models (SLMs) as Judge

Large judge models are expensive and slow. Purpose-trained SLMs (like Galileo's LUNA) offer a cost-effective alternative for production guardrails:

| Approach | Cost | Speed | Quality | Best For |
|---|---|---|---|---|
| Large LLM judge (GPT-4, Claude Opus) | High | Slow | Highest | Complex evaluation, calibration |
| SLM judge (fine-tuned) | Low | Fast | Good for in-scope | High-volume production guardrails |
| Deterministic rules | Very low | Instant | Perfect for what they cover | Known failure patterns (regex, schema) |

**Practical strategy:** Layer all three — deterministic rules catch known failures instantly, SLMs handle volume at low cost, large LLMs handle edge cases and calibration.

---

## LLM-as-a-Judge in RAG Systems

Two evaluation points in a RAG pipeline:

1. **Retrieval evaluation:** Was the retrieved chunk relevant to the question?
   - Prompt: "Given this question and these retrieved chunks, does chunk N contain information relevant to answering the question? Explain."

2. **Generation evaluation:** Is the answer grounded in the provided context?
   - Prompt: "Given this context and this answer, does the answer introduce factual claims not present in the context? Identify any hallucinations."

Both can run automatically in production to detect retrieval failures and hallucinations before they reach users.

---

## Key Takeaways

1. LLM-as-a-Judge fills the gap between deterministic metrics (too narrow) and human evaluation (too slow/expensive)
2. Biases are real and systematic — build mitigation into your judge design from the start
3. Reasoning before scoring is non-negotiable for production judges
4. Decompose criteria; never score "overall quality" as a single dimension
5. Validate your judge against known examples before trusting it in production
6. Layer deterministic rules + SLMs + large LLMs based on cost/quality requirements
