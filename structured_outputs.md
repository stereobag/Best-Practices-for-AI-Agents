# LLM Structured Outputs

*Source: "LLM Structured Outputs: The Only Way" — DecodingAI / decodingai.com*

---

## Why Structured Outputs

LLMs are probabilistic — they produce different phrasings, formats, and orderings across runs. Application code is deterministic — it expects predictable fields and types. Structured outputs are the formal contract between the two.

Without structure, parsing is fragile: a regex that works on 99% of outputs silently fails on the 1% with a different phrasing. With structure, failures surface immediately as validation errors rather than corrupting downstream state.

**Four concrete benefits:**

| Benefit | What It Solves |
|---|---|
| **Programmatic reliability** | Clean Python objects replace brittle regex parsing |
| **Type safety & validation** | Errors caught immediately, before downstream propagation |
| **Workflow orchestration** | Known schemas make it safe to pass outputs between steps, databases, and APIs |
| **Cost reduction** | Constraining output format eliminates wasted tokens on preambles and filler |

---

## Three Implementation Approaches

### Approach 1: From-Scratch JSON

Craft an explicit prompt specifying the desired JSON structure. Parse the response manually.

**Prompt pattern:**
```python
prompt = f"""
Compare generated document against ground truth.
Output must be valid JSON:
{{
  "scores": [
    {{
      "criterion": "revenue_forecast",
      "score": 0 or 1,
      "reason": "Your reasoning here."
    }},
    {{
      "criterion": "user_growth",
      "score": 0 or 1,
      "reason": "Your reasoning here."
    }},
    {{
      "criterion": "facts",
      "score": 0 or 1,
      "reason": "Your reasoning here."
    }}
  ]
}}

<generated_document>
{GENERATED_DOCUMENT}
</generated_document>

<ground_truth_document>
{GROUND_TRUTH_DOCUMENT}
</ground_truth_document>
"""
```

**Parsing helper:**
```python
import json

def extract_json_from_response(response: str) -> dict:
    response = response.replace("```json", "").replace("```", "")
    return json.loads(response)
```

**Limitation:** No runtime validation. Missing keys or type mismatches cause downstream failures rather than immediate detection.

---

### Approach 2: Pydantic Validation Layer

Define a Pydantic model. Generate the JSON schema from it. Pass the schema in the prompt. Validate the parsed response against the model.

**Model definition:**
```python
from typing import Literal
from typing_extensions import Annotated
import pydantic
from pydantic import Ge, Le

class CriterionScore(pydantic.BaseModel):
    """Holds the score and reason for a specific evaluation criterion."""
    criterion: Literal["revenue_forecast", "user_growth", "facts"]
    score: Annotated[int, Ge(0), Le(1)] = pydantic.Field(
        description="Binary score of the section."
    )
    reason: str = pydantic.Field(description="The reason for the given score.")

class Scores(pydantic.BaseModel):
    scores: list[CriterionScore]
```

**Validation:**
```python
parsed = extract_json_from_response(response)
scores = Scores.model_validate(parsed)  # Raises ValidationError immediately on schema violation
```

**Why Pydantic over `@dataclass` or `TypedDict`:** Both of those are static type hints only — they provide no runtime validation. Pydantic validates at instantiation time.

**Advantages over plain JSON:**
- Schema generated automatically from the Python class
- Enforces runtime type checking and constraint validation (`Ge(0)`, `Le(1)`)
- Raises `ValidationError` immediately, with field-level detail
- Supports nested models for hierarchical schemas

---

### Approach 3: Native API Structured Output

The simplest approach. Pass the Pydantic model directly to the API config. The API handles schema injection and parsing — the prompt can be written without any JSON instructions.

**Gemini SDK example:**
```python
from google import genai
from google.genai import types

client = genai.Client()

config = types.GenerateContentConfig(
    response_mime_type="application/json",
    response_schema=Scores  # Pydantic model passed directly
)

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=prompt,
    config=config
)

scores = response.parsed  # Returns a typed Scores instance — no parsing needed
```

**Simplified prompt (no JSON instructions needed):**
```python
prompt = f"""
You are an expert evaluator. Compare generated against ground truth
and score each criterion.

<generated_document>
{GENERATED_DOCUMENT}
</generated_document>

<ground_truth_document>
{GROUND_TRUTH_DOCUMENT}
</ground_truth_document>
"""
```

**Why this wins:** The API vendor optimizes model behavior for schema adherence at the inference level — more accurate and more cost-effective than asking the model to produce valid JSON through prompt instructions alone.

---

## Approach Comparison

| Approach | Validation | Prompt Complexity | Accuracy | Best For |
|---|---|---|---|---|
| From-scratch JSON | None (manual) | High — must describe schema in prompt | Lowest | Prototyping, simple schemas |
| Pydantic + JSON | Runtime (immediate errors) | Medium — schema injected, but prompt handles format | Medium | When native API support isn't available |
| Native API + Pydantic | Runtime + vendor-optimized | Low — prompt focuses on task only | Highest | Production; any API with native support |

---

## Best Practices

**Keep schemas simple.** Complex nested structures with many levels of nesting confuse LLMs. Flatten where possible; add nesting only when the data genuinely requires it.

**Use field descriptions.** Pydantic `Field(description=...)` is not just documentation — it gets serialized into the JSON schema and guides the model's generation for that field.

**Use XML tags to separate concerns.** Delineate different sections of the prompt clearly:
```
<generated_document>...</generated_document>
<ground_truth_document>...</ground_truth_document>
```
This prevents the model from blending instructions with input data.

**Always validate before downstream use.** Even with native API support, treat `response.parsed` as untrusted until validated by your application logic.

**Iterate with evaluation.** Don't assume a model or prompt works — measure it:
1. Configure multiple model/prompt variants
2. Run experiments for each
3. Compute business metrics (e.g., LLM-as-judge scores)
4. Analyze comparatively with LLMOps tooling
5. Select optimal configuration and iterate

---

## Structured Outputs in Agent Workflows

Structured outputs are especially critical in multi-step agent pipelines where one step's output is another step's input. A parsing failure in step 3 of a 10-step pipeline is far more expensive than a simple one-shot query failure.

**Checklist for agent pipelines:**
- [ ] Every inter-step payload has a Pydantic schema
- [ ] Validation runs at each step boundary, not just at the end
- [ ] Failures produce `ValidationError` with field-level detail, not silent `None` or partial data
- [ ] Schemas are versioned alongside prompts — a prompt change that alters output shape must update the schema

**Connection to LLM-as-Judge:** Structured outputs are the standard implementation pattern for LLM-as-Judge evaluators (see `llm_as_a_judge.md`). The judge outputs a typed score + reasoning object, not a free-form string — enabling programmatic aggregation across ChainPoll's 5 parallel judge instances.
