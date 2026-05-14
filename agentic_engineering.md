# Agentic Engineering vs. Vibe Coding
<!-- Covers Addy Osmani's agentic engineering framework (2026) contrasting professional AI-assisted development with vibe coding, plus enterprise risk analysis of vibe coding in production environments. -->

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
