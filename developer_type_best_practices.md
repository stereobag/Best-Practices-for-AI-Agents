# AI Best Practices by Developer Type
## Last Updated: 2026-03-20

---

## Universal Best Practices (All Developer Types)

Before diving into role-specific guidance, these principles apply universally:

### 1. The Supervised Collaboration Model
Do not let AI agents code entire features unattended. Use a "supervised pair programmer" model:
- Keep oversight at each step
- Intervene when outputs drift from intent
- Think of AI as a brilliant junior developer: fast, capable, but lacking deep production judgment

### 2. Context is Everything
- Always provide architectural context before starting agentic tasks
- Use project-level steering documents (CLAUDE.md, .cursorrules, Kiro Steering) to encode standards
- Include relevant files, not just the file being modified
- State constraints explicitly: performance budgets, security requirements, API contracts

### 3. Small Increments + Test After Each
- Generate code in small, verifiable increments
- Run tests after each AI-generated integration
- Never let AI generate hundreds of lines without a verification checkpoint

### 4. Prompt Engineering is a Core Skill
- Be explicit about what you do NOT want (e.g., "do not add new dependencies")
- Specify output format, language version, framework conventions
- For agentic tasks: define success criteria upfront ("task is done when all tests pass and no linting errors exist")

### 5. Review AI Code as Carefully as Human Code
- AI code passes tests and matches conventions — but can hide subtle bugs and edge cases
- Review PRs from AI agents with the same rigor as any team member
- Maintain code ownership: you are accountable for what ships, not the AI

---

## Frontend Engineers

### Recommended Tools
- **Primary:** Cursor (fast iteration, component-level work, strong React/Vue/Svelte support)
- **Secondary:** Claude Code (for complex state management architecture or full-page refactors)
- **Design-to-code:** Vercel v0, Figma AI plugins for component scaffolding

### High-Value AI Use Cases
1. **Component scaffolding** — Generate boilerplate React/Vue/Angular components with correct prop types
2. **CSS/Tailwind generation** — Describe visual intent in natural language; let AI produce styles
3. **Test writing** — Generate unit and snapshot tests for UI components
4. **Accessibility audits** — Prompt AI to review components for ARIA compliance
5. **Design system enforcement** — Use AI to check components against design system tokens
6. **Cross-browser/responsive debugging** — Describe visual bug; AI suggests fixes

### Best Practices
- Use AI for initial scaffolding; refine manually for pixel-perfect accuracy
- Provide design system documentation as context in every session
- AI cannot replace visual judgment — always verify UI output in browser
- Use Cursor's Tab Autocomplete for rapid iteration on component variants
- For full-page implementations from Figma designs, v0 or similar design-to-code tools outperform general coding agents

### Skills AI Cannot Replace (Frontend)
- Visual design judgment and pixel-level precision
- User empathy and UX decision-making
- Design system architecture and token governance
- Performance profiling and optimization intuition
- Cross-team design-engineering collaboration

---

## Backend Engineers

### Recommended Tools
- **Primary:** Claude Code (architectural complexity, multi-service changes, security analysis)
- **Secondary:** Cursor or Codex (for API endpoint scaffolding, routine CRUD operations)
- **CI/CD:** Codex or Claude Code in automated pipeline agents

### High-Value AI Use Cases
1. **API scaffolding** — Generate REST/GraphQL endpoints with validation and error handling
2. **Database schema design** — Describe data model in plain English; AI generates migration scripts
3. **Code review automation** — AI agents review PRs for security issues, N+1 queries, missing error handling
4. **Test generation** — Integration tests, edge case identification, load test scripts
5. **Documentation** — Generate OpenAPI specs, README docs, inline comments from code
6. **Refactoring** — Extract services, modularize monoliths, upgrade dependency versions
7. **Security scanning** — Prompt AI to audit code for OWASP Top 10 vulnerabilities
8. **Log analysis** — Feed log patterns to AI for anomaly detection and debugging suggestions

### Best Practices
- Always provide system architecture context (what services exist, what contracts are in place)
- For database work: never apply AI-generated migrations without manual review and staging validation
- Use AI for test coverage expansion — a high-ROI, low-risk use case
- Run AI-suggested refactors in branches with full regression suites before merging
- For security-sensitive code: use Claude Code (highest code quality, zero security issues in evaluations)
- Encode coding standards in CLAUDE.md or .cursorrules — AI will follow them consistently

### Agentic Workflows for Backend
- **PR Automation Agent:** Automatically generates PR descriptions, test summaries, and risk assessments
- **Dependency Update Agent:** Scans for outdated dependencies, generates upgrade PRs, runs tests
- **API Documentation Agent:** Watches for code changes, auto-updates API docs
- **Performance Regression Agent:** Runs benchmarks on PRs, flags performance regressions

---

## Machine Learning Engineers

### Recommended Tools
- **Primary:** Claude Code (complex reasoning on model architectures, training pipeline debugging)
- **Secondary:** Jupyter AI + Cursor for notebook-based exploration
- **Data pipeline:** Codex or Claude Code for ETL automation

### High-Value AI Use Cases
1. **Experiment scaffolding** — Generate training scripts, evaluation harnesses, logging setups
2. **Hyperparameter search** — AI suggests search spaces based on model architecture
3. **Data pipeline generation** — Generate preprocessing, augmentation, and validation code
4. **Model architecture exploration** — Describe a problem; AI suggests and implements candidate architectures
5. **Research paper implementation** — Feed an arXiv paper; AI scaffolds the implementation
6. **Evaluation suite generation** — Generate benchmark datasets and metrics code
7. **Debugging training instabilities** — Describe symptoms; AI suggests fixes (learning rate, batch norm, etc.)
8. **MLOps scaffolding** — Generate Dockerfile, Kubernetes configs, serving code for model deployment

### Best Practices
- AI-generated ML code requires domain validation — mathematical correctness is not guaranteed
- Always verify loss functions, metrics, and data splits independently
- Use AI for boilerplate (data loading, logging, experiment tracking setup) — highest ROI, lowest risk
- For novel architectures: use AI to implement known components; architect novel parts yourself
- Treat AI-generated model code as a "first draft" requiring expert review before training runs
- For large model training: AI-generated bugs can cost hundreds of GPU-hours — review carefully

### Emerging AI-for-ML Workflows
- **Auto-EDA agents:** Automated exploratory data analysis — AI generates visualizations and statistical summaries
- **Debugging agents:** Feed training logs and loss curves; AI identifies common failure modes
- **Literature-to-code agents:** AI reads recent papers and generates experimental implementations
- **Model card generation:** AI auto-generates model cards from training configs and evaluation results

---

## Platform / DevOps / SRE Engineers

### Recommended Tools
- **Primary:** Claude Code (IaC generation, complex YAML/Terraform, incident analysis)
- **Secondary:** GitHub Copilot (for GitHub Actions workflows)

### High-Value AI Use Cases
1. **Infrastructure as Code generation** — Terraform, Pulumi, CloudFormation from natural language specs
2. **CI/CD pipeline construction** — GitHub Actions, GitLab CI workflows from deployment requirements
3. **Incident analysis** — Feed runbooks + error logs; AI suggests RCA and remediation steps
4. **Kubernetes manifest generation** — Deployments, services, ingress configs
5. **Security policy generation** — IAM policies, network policies, security group rules
6. **Monitoring configuration** — Prometheus rules, alerting configs, dashboard generation
7. **Runbook automation** — Convert manual runbooks into automated scripts

### Best Practices
- Never apply AI-generated IaC to production without plan review and staging validation
- Use AI to generate multiple IaC options; choose based on your constraints
- AI is excellent at converting manual runbooks to automation — high ROI use case
- For security policies: always have a security engineer review AI-generated IAM/network policies

---

## The "AI-Native" Workflow Model (2026)

The most productive developers in 2026 follow this pattern:

```
1. ARCHITECT (human) → Define the problem, constraints, success criteria
2. DELEGATE (AI agent) → Implement the solution autonomously
3. REVIEW (human) → Validate correctness, security, performance
4. ITERATE (human + AI) → Refine together until production-ready
5. SHIP (human decision) → Human makes the final deployment decision
```

Engineers now use AI in approximately 60% of their work, but fully delegate only 0-20% of tasks. The role is shifting from "code writer" to "outcome orchestrator."
