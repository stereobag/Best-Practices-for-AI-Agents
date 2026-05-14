# Eval Engineering Desk Reference

*Source: Eval Engineering Cheatsheet — evalengineering.org*

> "Eval engineering isn't testing. It's building reusable intellectual property that governs your AI system in production."
> "You can't improve what you can't measure. You can't measure what you haven't defined."

---

## The Mental Model Shift

| Old Model | Eval Engineering |
|---|---|
| Evals are debugging tools | Evals are **governance systems** |
| Run once before deployment | Run **continuously** in production |
| Generic accuracy metrics | Domain-specific precision |
| Sample 10% of traffic | Cover **100%** of traffic |
| Static test sets | Adaptive evaluation |
| Cost center | **Strategic asset** |
| Measures behavior | **Governs** behavior |

### What Happens Without Evals

| Trap | Description |
|---|---|
| **Endless Pilot Loop** | Demos well, never graduates to production |
| **Firefighting Trap** | Reacting to failures instead of preventing them |
| **Rebuild Tax** | Every project reconstructs infra from scratch |
| **Accuracy Plateau** | Stuck at 70%, nothing moves the needle |

### What Evals Enable

| Chore | Without Evals | With Evals |
|---|---|---|
| Model upgrade | Weeks of manual testing | Run suite overnight, ship in days |
| Prompt change | Hope nothing broke | Know exactly what changed |
| Bug report | Guess and check | Reproduce, fix, add to regression |
| New hire | Tribal knowledge | Read the test cases |

---

## The 5-Stage Eval Engineering Lifecycle

```
Stage 1: LLM-as-Judge (60-70% accuracy)
  → Fast to set up. Wrong 3/10 times.

Stage 2: SME Refinement (90-95% accuracy)
  → Domain experts review failures, articulate criteria.

Stage 3: Develop with Evals (CI/CD)
  → Benchmark and A/B test. Regression testing in CI/CD.

Stage 4: Scale with SLMs (<150ms latency)
  → Fine-tune 3-8B models. Same accuracy at 10-40× lower cost.

Stage 5: Deploy Guardrails (100% coverage)
  → Real-time scores powering governance. Block risky outputs.
```

---

## Chapter 2: LLM-as-Judge

### Start with Code-Based Evals

| Type | Cost | Latency | Accuracy | Use When |
|---|---|---|---|---|
| **Code-based** (exact match, regex, schema) | ~$0 | <10ms | 100% | Always start here first |
| **LLM judge** (semantic quality, open-ended) | $0.01–0.10/eval | 2–4s | 90–95% | Judgment is subjective |

### 7 Principles for Judge Prompts

1. **Be specific.** "Is it helpful?" is untestable. "Does it include a step-by-step solution?" is. Define exactly what pass and fail look like.

2. **Clarify vague terms.** Replace "appropriate tone" with "formal, no slang, addresses user by name." If two people could disagree on the rating, rewrite it.

3. **Binary output.** Pass or Fail only. Likert scales just move the ambiguity from the answer to the score.

4. **Few-shot examples.** Show the judge what good and bad look like. Include edge cases — the ones right on the boundary.

5. **Explicit decision rules.** Remove wiggle room. "If no source is cited, mark FAIL regardless of accuracy." Hard rules prevent soft reasoning.

6. **One judge, one criterion.** "Helpful but factually wrong" breaks a single judge. Split it: one judges helpfulness, another judges accuracy.

7. **Reasoning before verdict.** Make the judge think before ruling. Chain-of-thought before the final label boosts accuracy.

### Accuracy Progression

| Judge Configuration | Accuracy |
|---|---|
| Custom LLM judge (untuned) | 67% |
| GPT-4 base | 80% |
| Domain-tuned with SME refinement | 95% |

### Prompt Quality Comparison

| Element | Basic | Refined |
|---|---|---|
| Role | None | Clear domain context |
| Criteria | Vague | Numbered, testable |
| Examples | None | Few-shot + reasoning |
| Output | Ambiguous | Reasoning then Pass/Fail |
| Accuracy | ~60% | 75–80% |

### ChainPoll — Multi-Judge Voting

Single LLM judge = noisy (66–68% AUROC). Fix: 5 judges voting in parallel.

**Settings:** Temperature 0 · 5 parallel judges · Score = (# Fail) / 5

**Example:** 3 Fail, 2 Pass → 0.60 hallucination risk score

**AUROC Benchmark:**

| Method | AUROC | vs ChainPoll |
|---|---|---|
| **ChainPoll (5 judges)** | **0.781** | — |
| SelfCheck-Bert | 0.673 | -14% |
| SelfCheck-NGram | 0.644 | -18% |
| G-Eval | 0.579 | -26% |
| GPTScore | 0.524 | -33% |

Cost: $0.015/eval vs $0.060 for GPT-4. 4× cheaper.

### 3 Biases That Kill Accuracy

| Bias | Magnitude | Fix |
|---|---|---|
| **Position Bias** | 35% of judgments change based on answer order | Swap positions, run pairwise twice |
| **Verbosity Bias** | LLMs prefer longer answers 85% of the time | Add "evaluate quality independently of length" to judge prompt |
| **Self-Preference** | Models favor own outputs by 10–25% | Use a different model family for judge vs. generator |

### F1 Score Benchmarks

| Score | Rating |
|---|---|
| ≥ 0.95 | Outstanding |
| ≥ 0.85 | Excellent |
| 0.70–0.85 | Substantial |
| < 0.50 | Poor |

---

## Chapter 3: SME Refinement

### Critique Shadowing — 7 Steps

1. **Expert defines quality** — one "benevolent dictator" with final call on criteria
2. **Build dataset** — features × scenarios × personas
3. **Write critiques** — Pass/Fail + documented reasoning per example
4. **Fix broken systems** — don't eval what's already broken (fix it first)
5. **Build judge** — use critiques as few-shot examples
6. **Track metrics** — F1, Cohen's Kappa, ICC
7. **Iterate** — until >90% agreement between judge and expert

### Ground Truth Dataset Requirements

| Requirement | Target |
|---|---|
| Dataset size | 200–500 representative examples |
| Minimum viable | 100 examples by lead expert |
| Per failure mode | At least 20 examples per mode |
| Inter-rater agreement | Cohen's Kappa > 0.8 |
| Split | Train 20% / Dev 40% / Test 40% |
| Refresh cadence | Quarterly |

**Do:** 5–10 few-shot examples · balance pass/fail · diverse scenarios · borderline cases · match production distribution · clear critiques

**Don't:** All passing examples · all similar scenarios · restate verdicts without reasoning · synthetic data without SME check · no held-out test set

### Time Budget (Banking Chatbot Case Study)

| Task | Time |
|---|---|
| Labeling 150 examples | 4h |
| Disagreement review (3×30 min) | 5h |
| Prompt iteration | 2h |
| Docs + handoff | 1h |
| **Total** | **12h** |

**Result:** 71% → 94% accuracy over 3 refinement cycles

| Cycle | Gain | Discovery |
|---|---|---|
| Cycle 1 | +11% | Educational explanations ≠ financial advice |
| Cycle 2 | +7% | "Strong momentum" phrasing counts as advice |
| Cycle 3 | +5% | "Should I invest in X?" requires deflection, not answering |

---

## Chapter 4: Scaling with SLMs

### Why LLM Judges Break at Scale

| Problem | Impact |
|---|---|
| **Cost ceiling** | $10k–50k/day for M conversations; multiply per metric |
| **Latency barrier** | 1–3s per eval; 5 evals sequential = 15s; too slow for real-time |
| **Prompting ceiling** | Last 5–6% resists prompting; prompt grows, attention fragments |
| **Subsampling trap** | Rare failures don't survive 1% sampling; worst failures are always rarest |

### LLM vs SLM Judge Comparison

| | LLM Judge | SLM Judge |
|---|---|---|
| Cost/1M evals | $10k–50k | $200–1k |
| Latency | 1–3s | 15–150ms |
| Real-time feasible | No | Yes |
| 100% coverage | Prohibitive | Standard |
| Accuracy | 90–95% | 90–95%+ |

### SLM Selection Guide

| Size | Latency (L4) | Best For |
|---|---|---|
| 3B | 15–60ms | Real-time guardrails, cost-sensitive |
| 8B | 50–150ms | Async monitoring, strict >95% accuracy |

**SLMs excel at:** Binary classification · high-volume eval · real-time <100ms · on-prem/private deployment

**SLMs struggle with:** Subjective quality · novel failure modes · evolving criteria · multi-factor tradeoffs

### Output Modes

| Mode | Latency | Use Case |
|---|---|---|
| Single-token (logits) | 15–50ms | Real-time guardrails |
| Verdict-only (PASS/FAIL) | 50–100ms | Routing |
| Reasoning | 200–500ms | Explanations, audit trails |

### Training Data Requirements for SLM

- Test set (first): 300–500 SME-labeled, min 100/class
- Training set: 1K–10K, balanced 50/50
- Augmentation: Synthetic from LLMs, SME-verified
- Hard negatives: Looks like a violation, but isn't
- Document all: Source, labeler, date, version

---

## Chapter 5: Guardrails

### Metrics by Use Case

**RAG Applications:**

| Layer | Metric | Target |
|---|---|---|
| Retrieval | Chunk Attribution | >80% |
| Retrieval | Chunk Utilization | >80% |
| Retrieval | Chunk Relevance | >90% |
| Generation | Context Adherence | >80% |
| Generation | Completeness | >90% |
| Generation | Groundedness | >90% |

**Agent / Multi-Step:**

| Metric | Target |
|---|---|
| Tool Selection Quality | 1.0 |
| Tool Error Rate | 1.0 (zero errors) |
| Action Completion | Binary pass/fail |
| Agent Efficiency | (detect repeated/looping actions) |
| Agent Flow | (detect off-path behavior) |

**General LLM:**

| Metric | Target |
|---|---|
| Instruction Adherence | >0.9 |
| Correctness | >90% |
| Conciseness | Monitor |
| Tone (brand voice) | Monitor |

### Production Guardrail Actions

1. **Block risky outputs** — score below threshold = blocked before delivery
2. **Route by confidence** — low confidence → human review; high → auto-approve
3. **Trigger HITL** — uncertain cases escalated to experts
4. **Enforce policy** — real-time scores drive governance
5. **Capture and refine** — 100% observability feeds back into eval loop

### 7 Mistakes to Avoid

1. **Too many metrics** — start with one binary judge
2. **Generic off-the-shelf** — tune for your domain
3. **Outsource error analysis** — look at the data yourself
4. **Likert 1–5 scales** — use binary Pass/Fail instead
5. **No few-shots** — critical for calibration
6. **Same model for judge and generator** — 10–25% self-preference bias
7. **Single judge** — use ChainPoll voting (3/5/7 judges)

### ChainPoll Prompt Template

```
You are an expert evaluator for [DOMAIN].

EVALUATION CRITERIA:
1. [Criterion]: [Definition with examples]
2. [Criterion]: [Definition with examples]

SCORING:
"Pass": Meets all criteria (minor issues acceptable)
"Fail": Significant errors or omissions

<examples>
  <example>
    <input>...</input>
    <response>...</response>
    <critique>...</critique>
    <judgment>Pass/Fail</judgment>
  </example>
</examples>

Evaluate step by step, then output:
{"reasoning": "...", "judgment": "Pass/Fail"}
```

---

## Chapter 6: Eval Engineering Checklist

### Pre-Production — Build the Foundation

**Define Quality:**
- [ ] Identify one domain expert as "benevolent dictator"
- [ ] Write down what "good" means in specific, testable terms
- [ ] Define 3–5 failure modes you care about most
- [ ] Create diverse test dataset (200–500 examples from production)

**Build First Judge:**
- [ ] Start with code-based evals for deterministic checks
- [ ] Write LLM judge prompt with explicit criteria
- [ ] Add 5–10 few-shot examples (balanced pass/fail)
- [ ] Include edge cases that cause disagreement
- [ ] Use binary Pass/Fail, not Likert scales
- [ ] Require chain-of-thought before verdict

**Refine with SME:**
- [ ] Have expert label 100+ examples with reasoning
- [ ] Run disagreement analysis (find where judge and expert differ)
- [ ] Iterate until >90% agreement (F1 > 0.85)
- [ ] Split ground truth: Train 20% / Dev 40% / Test 40%
- [ ] Document criteria version and all edge case decisions

**Set Up ChainPoll:**
- [ ] Configure 5 parallel judges at temperature 0
- [ ] Validate AUROC against your ground truth
- [ ] Test for position, verbosity, and self-preference bias

### Post-Production — Ship and Monitor

**CI/CD Integration:**
- [ ] Add eval suite to CI/CD pipeline
- [ ] Block deploys that fail quality thresholds
- [ ] A/B test every prompt change against scenario bank
- [ ] Set up regression testing for known failure modes
- [ ] Track latency, token usage, cost per task as baselines

**Production Monitoring:**
- [ ] Enable observability on 100% of production traffic
- [ ] Set up alerts for eval score drops below threshold
- [ ] Configure confidence-based routing (low → human, high → auto)
- [ ] Implement real-time guardrails for safety and compliance
- [ ] Log all evaluation decisions for audit trails

**Continuous Improvement:**
- [ ] Review production failures weekly
- [ ] Add new failure modes to ground truth dataset
- [ ] Refresh ground truth quarterly
- [ ] Re-run disagreement analysis after criteria changes
- [ ] Track F1 trend over time (should only go up)

**Team Operations:**
- [ ] Document all eval criteria in a shared rubric
- [ ] New hires onboard by reading test cases
- [ ] Product team references specific failing cases, not vibes

### At Scale — Optimize Cost and Coverage

**SLM Transition:**
- [ ] Create 300–500 SME-labeled test set (min 100/class)
- [ ] Build training set: 1K–10K balanced examples
- [ ] Generate synthetic data, verify with SMEs before use
- [ ] Include hard negatives in training data
- [ ] Select model size: 3B (real-time) or 8B (accuracy)
- [ ] Fine-tune with LoRA for multi-metric evaluation

**Production SLM Deployment:**
- [ ] Validate SLM accuracy matches LLM judge on test set
- [ ] Deploy single-token mode for real-time guardrails
- [ ] Move from sampling to 100% traffic evaluation
- [ ] Set up confidence routing with SLM scores
- [ ] Monitor for distribution drift between training and production

**Cost and Governance:**
- [ ] Track cost reduction vs LLM judge baseline
- [ ] Measure latency: target sub-150ms for guardrails
- [ ] Set up policy enforcement using real-time eval scores
- [ ] Configure human-in-the-loop for uncertain cases
- [ ] Build feedback loop: production failures feed back into training
