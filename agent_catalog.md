# Agent Catalog: Agents to Build for Developer Productivity
<!-- A catalog of 14 production-ready agents across development lifecycle, quality & security, developer support, and ML workflows — with purpose, inputs, outputs, triggers, tools, and ROI for each. -->

---

## Catalog of Agents to Build

### Development Lifecycle Agents

#### 1. PR Automation Agent
**Purpose:** Automate PR creation, description, and initial review
**Inputs:** Diff, commit messages, related ticket
**Outputs:** PR description, risk assessment, test summary, reviewer suggestions
**Trigger:** Git push to feature branch
**Tools:** Claude Code / GitHub Actions + Copilot
**ROI:** Saves 15-30 min per PR; improves PR quality for review

#### 2. Code Review Agent
**Purpose:** First-pass code review before human reviewers
**Inputs:** PR diff, codebase context, coding standards
**Outputs:** Inline comments on: security issues, performance problems, missing tests, style violations
**Trigger:** PR opened/updated
**Tools:** Claude Code, Codex, or GitHub Copilot (Agent Mode)
**ROI:** Catches 60-70% of common issues before human review

#### 3. Test Generation Agent
**Purpose:** Automatically generate unit, integration, and edge-case tests
**Inputs:** New/modified functions + codebase context
**Outputs:** Test file with unit tests, edge cases, and mock setups
**Trigger:** PR opened, or on-demand
**Tools:** Claude Code (highest quality), Cursor
**ROI:** Brings test coverage from 60% → 85%+ with minimal developer effort

#### 4. Dependency Update Agent
**Purpose:** Keep dependencies current with automated PRs
**Inputs:** package.json / requirements.txt / go.mod + changelog data
**Outputs:** Upgrade PRs with summary of breaking changes and required code updates
**Trigger:** Weekly scheduled run
**Tools:** Claude Code + Renovate Bot
**ROI:** Eliminates manual dependency management; reduces security vulnerabilities

#### 5. Documentation Agent
**Purpose:** Keep docs in sync with code changes
**Inputs:** Code diff, existing docs, API specs
**Outputs:** Updated README, API docs, inline comments, changelog entries
**Trigger:** PR merge to main
**Tools:** Claude Code
**ROI:** Eliminates documentation lag; improves onboarding time

---

### Quality & Security Agents

#### 6. Security Audit Agent
**Purpose:** Automated security review of every PR
**Inputs:** Code diff + security policy documents
**Outputs:** Security issues flagged with severity (CVSS score), remediation suggestions
**Trigger:** PR opened
**Tools:** Claude Code (best security track record)
**ROI:** Catches OWASP Top 10 issues before they reach staging

#### 7. Performance Regression Agent
**Purpose:** Detect performance regressions introduced by code changes
**Inputs:** PR diff + benchmark results
**Outputs:** Performance delta report, slowdown attribution, optimization suggestions
**Trigger:** PR opened on performance-sensitive paths
**Tools:** Claude Code + custom benchmarking harness
**ROI:** Prevents performance regressions from reaching production

#### 8. Quality Gate Agent
**Purpose:** Enforce quality standards before merge — refuses to approve until all checks pass
**Inputs:** Test results, coverage report, linting output, security scan
**Outputs:** Pass/fail decision with detailed remediation plan
**Trigger:** Pre-merge check
**Tools:** Claude Code, Codex
**ROI:** Reduces post-deploy incidents; enforces standards consistently

---

### Developer Support Agents

#### 9. Onboarding Agent
**Purpose:** Guide new developers through codebase ramp-up
**Inputs:** Developer questions, codebase, architecture docs
**Outputs:** Contextual answers, code walkthroughs, suggested starting tasks
**Trigger:** On-demand (Slack bot or IDE integration)
**Tools:** Claude Code with RAG over internal docs
**ROI:** Reduces new developer ramp-up from 3 months → 4-6 weeks

#### 10. Incident Response Agent
**Purpose:** Assist SREs during production incidents
**Inputs:** Error logs, runbooks, system metrics, recent deployments
**Outputs:** Root cause hypotheses, remediation steps, rollback recommendations
**Trigger:** PagerDuty/OpsGenie alert
**Tools:** Claude Code
**ROI:** Reduces MTTR by 30-50%

#### 11. Architecture Decision Agent
**Purpose:** Help developers make informed architectural decisions
**Inputs:** Problem description, existing architecture, constraints
**Outputs:** Option analysis with tradeoffs, recommendation, implementation sketch
**Trigger:** On-demand
**Tools:** Claude Code (deepest reasoning)
**ROI:** Reduces architecture review cycles; improves decision quality

---

### ML-Specific Agents

#### 12. Experiment Setup Agent
**Purpose:** Scaffold ML experiments from high-level descriptions
**Inputs:** Model type, dataset description, evaluation criteria
**Outputs:** Training script, evaluation harness, experiment tracking setup, Dockerfile
**Trigger:** On-demand
**Tools:** Claude Code + Jupyter AI

#### 13. Training Debug Agent
**Purpose:** Diagnose training instabilities and poor convergence
**Inputs:** Training logs, loss curves, model config, dataset stats
**Outputs:** Diagnosis of likely issues + prioritized fix recommendations
**Trigger:** On-demand during training runs
**Tools:** Claude Code

#### 14. Auto-EDA Agent
**Purpose:** Automated exploratory data analysis
**Inputs:** Dataset (CSV, Parquet, SQL query)
**Outputs:** Statistical summary, visualizations, data quality report, feature recommendations
**Trigger:** On-demand or on new dataset arrival
**Tools:** Claude Code + Jupyter AI
