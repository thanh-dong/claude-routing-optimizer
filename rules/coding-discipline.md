---
description: Behavioral guardrails to reduce common LLM coding mistakes. Applies to all code changes.
alwaysApply: true
---

# Coding Discipline

## 1. Think Before Coding

- State assumptions explicitly. If uncertain, ask before implementing.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

## 3. Surgical Changes

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated issues, mention them — don't fix them.
- Remove only imports/variables/functions that YOUR changes made unused.

The test: every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

Transform tasks into verifiable goals before starting:
- "Add validation" -> write tests for invalid inputs, then make them pass
- "Fix the bug" -> write a test that reproduces it, then make it pass
- "Refactor X" -> ensure tests pass before and after

For multi-step tasks, state a brief plan with verification at each step.
Loop until verified — don't declare success without evidence.
