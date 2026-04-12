# Plugin Routing Guide

This guide ONLY applies when a task matches multiple plugins. For tasks that clearly match a single skill description, use that skill directly without consulting this guide.

**Notation**: `/cmd` = slash command. `agent:name` = spawn via Agent tool. *italic* = auto-trigger skill (activates from context, not invoked directly).

## Overlap Resolution

**Code review**:
- Small PR (<50 lines, single concern) -> `/review` alone
- Need blast radius / what breaks? -> `/gitnexus-pr-review`
- Language-specific idioms -> spawn `ecc:{lang}-reviewer` agent (match PR's primary language)
- Important PR (>50 lines or shared code) -> chain: `/gitnexus-pr-review` -> `ecc:{lang}-reviewer` agent -> `/review`

**Frontend design** (4 sources):
- Generate design system from scratch -> `/ui-ux-pro-max`
- Design consultation with DESIGN.md output -> `/design-consultation` (gstack)
- Build production UI -> `/impeccable:frontend-design`
- Polish/refine existing UI -> `/impeccable:polish`, `/impeccable:audit`
- Visual QA of running UI -> `/design-review` (gstack)
- Standalone artifacts (canvas art, HTML artifacts) -> `/document-skills:frontend-design`

**Testing**:
- Unit test discipline (TDD) -> `/ecc:tdd`
- Language-specific test patterns -> `/ecc:go-test`, `/ecc:rust-test`, `/ecc:kotlin-test`, etc.
- Browser-based visual QA -> `/qa` (gstack)
- Playwright E2E regression suites -> `/ecc:e2e`

**Debugging**:
- Compile/build error? -> ECC build resolver directly (`/ecc:go-build`, `/ecc:rust-build`, etc.)
- Need to trace callers/dependencies/flow? -> `/gitnexus-debugging`
- Runtime bug requiring reproduction + hypothesis? -> `/investigate` (gstack)
- Unknown cause? -> `/gitnexus-debugging` first (fast graph query), then `/investigate` if root cause unclear

**Architecture & Planning**:
- C4 architecture documentation + diagrams -> `/c3`
- System design decisions + trade-offs -> spawn `ecc:architect` agent
- Implementation plan with steps -> `/ecc:plan`
- Plan review pipeline (CEO/design/eng) -> `/autoplan` (gstack)

**Security**:
- Code-level OWASP checks -> spawn `ecc:security-reviewer` agent
- Infrastructure audit (secrets, STRIDE) -> `/cso` (gstack)
- Critical systems -> layer both

**Refactoring**:
- Graph-aware rename/move/extract with dry-run -> `/gitnexus-refactoring`
- Impact analysis before changes -> `/gitnexus-impact-analysis`
- Dead code cleanup -> spawn `ecc:refactor-cleaner` agent

**Performance**:
- Code-level optimization -> spawn `ecc:performance-optimizer` agent
- Regression detection with benchmarks -> `/benchmark` (gstack)

**Shipping**:
- Release workflow (test, review, version, PR) -> `/ship` (gstack)
- Merge + deploy + verify -> `/land-and-deploy` (gstack)
- Post-deploy monitoring -> `/canary` (gstack)
- Post-ship doc updates -> `/document-release` (gstack)

**Documentation**:
- Office docs (docx, pptx, xlsx, pdf) -> `/document-skills:*`
- HTML presentations -> `/ecc:frontend-slides`
- Architecture docs (C4) -> `/c3`
- Post-release doc sync -> `/document-release` (gstack)

## Workflows

**New feature** (backend): *search-first* applies automatically -> `/ecc:plan` -> implement -> `/ecc:tdd` -> `/qa` -> then PR workflow

**New feature** (with UI): *search-first* applies automatically -> `/ecc:plan` -> `/ui-ux-pro-max` (design system) -> `/impeccable:frontend-design` (build) -> `/impeccable:polish` -> `/qa` -> then PR workflow

**Important PR**: `/gitnexus-pr-review` -> `ecc:{lang}-reviewer` agent -> `ecc:security-reviewer` agent -> `/review`

**Bug fix** (compile error): `/ecc:{lang}-build` -> fix -> `/ecc:tdd` (regression test)

**Bug fix** (runtime): `/gitnexus-debugging` -> `/investigate` -> fix -> `/ecc:tdd` -> `/qa` (if UI bug)

**Release**: `/ship` -> `/land-and-deploy` -> `/canary` -> `/document-release`

## Parallel Agents

For comprehensive review, spawn in parallel via Agent tool:
- `ecc:code-reviewer` + `ecc:security-reviewer` + `ecc:performance-optimizer`

For architecture, use Opus-tier: `ecc:architect`, `ecc:planner`
