# Plugin Routing Guide

This guide only applies when a task matches multiple plugins. Single-match tasks: use that skill directly.

**Notation**: `/cmd` = slash command. `agent:name` = spawn via Agent tool. *italic* = auto-trigger.

## Overlap Resolution

**Code review**:
- Small PR (<50 lines) -> `/review` alone
- Need blast radius? -> `/gitnexus-pr-review`
- Language-specific idioms -> spawn `ecc:{lang}-reviewer`
- Important PR (>50 lines) -> chain: `/gitnexus-pr-review` -> `ecc:{lang}-reviewer` -> `/review`

**Frontend design**:
- Design system from scratch -> `/ui-ux-pro-max`
- Design consultation -> `/design-consultation`
- Build production UI -> `/impeccable:frontend-design`
- Polish existing UI -> `/impeccable:polish`, `/impeccable:audit`
- Visual QA of running UI -> `/design-review`
- Standalone artifacts -> `/document-skills:frontend-design`

**Testing**:
- TDD workflow -> `/ecc:tdd`
- Language-specific test patterns -> `/ecc:{lang}-test`
- Browser visual QA -> `/qa`
- E2E regression suites -> `/ecc:e2e`

**Debugging**:
- Compile/build error? -> `/ecc:{lang}-build` directly
- Trace callers/flow? -> `/gitnexus-debugging`
- Runtime bug needing reproduction? -> `/investigate`
- Unknown cause? -> `/gitnexus-debugging` first, then `/investigate`

**Architecture & Planning**:
- C4 architecture + diagrams -> `/c3`
- System design decisions -> spawn `ecc:architect`
- Implementation plan -> `/ecc:plan`
- Plan review pipeline -> `/autoplan`

**Security**:
- Code-level OWASP -> spawn `ecc:security-reviewer`
- Infrastructure audit -> `/cso`
- Critical systems -> layer both

**Refactoring**:
- Rename/move/extract -> `/gitnexus-refactoring`
- Impact analysis -> `/gitnexus-impact-analysis`
- Dead code cleanup -> spawn `ecc:refactor-cleaner`

**Performance**:
- Code-level optimization -> spawn `ecc:performance-optimizer`
- Regression benchmark detection -> `/benchmark`

**Shipping**:
- Release workflow -> `/ship`
- Deploy + verify -> `/land-and-deploy`
- Post-deploy monitoring -> `/canary`
- Post-ship docs -> `/document-release`

**Documentation**:
- Office docs -> `/document-skills:*`
- HTML presentations -> `/ecc:frontend-slides`
- Architecture docs (C4) -> `/c3`

## Workflows

**New feature** (backend): `/ecc:plan` -> implement -> `/ecc:tdd` -> `/qa` -> PR

**New feature** (with UI): `/ecc:plan` -> `/ui-ux-pro-max` -> `/impeccable:frontend-design` -> `/impeccable:polish` -> `/qa` -> PR

**Important PR**: `/gitnexus-pr-review` -> `ecc:{lang}-reviewer` -> `ecc:security-reviewer` -> `/review`

**Bug fix** (compile error): `/ecc:{lang}-build` -> fix -> `/ecc:tdd`

**Bug fix** (runtime): `/gitnexus-debugging` -> `/investigate` -> fix -> `/ecc:tdd` -> `/qa`

**Release**: `/ship` -> `/land-and-deploy` -> `/canary` -> `/document-release`

## Parallel Agents

Spawn in parallel: `ecc:code-reviewer` + `ecc:security-reviewer` + `ecc:performance-optimizer`

Architecture (Opus-tier): `ecc:architect`, `ecc:planner`
