# Autoresearch: prompt-assistant skill

## Goal
Develop a `prompt-assistant` skill that refines long unstructured brainstorming prompts into structured, token-efficient prompts the user can hand off to Claude for follow-up work.

## Metric
Primary: `accuracy` = percentage of assertions in `tests/prompt-assistant-assertions.txt` that pass.
Secondary (logged, not gated): `word_count` of `skills/prompt-assistant/SKILL.md` — watch for inverse correlation with accuracy (bloat without quality = bad).

## Direction
`accuracy` — higher is better.

## Scope
- **Modifiable**: `skills/prompt-assistant/SKILL.md`
- **Read-only / structural**: `tests/bench-prompt-assistant.sh`, `tests/prompt-assistant-assertions.txt`, `autoresearch.sh`, `autoresearch.md`
- The agent may ADD new assertions when it discovers a quality dimension not yet encoded, but must commit the assertions change as a separate run from the SKILL.md change so the metric delta is interpretable.

## Verify command
`bash autoresearch.sh`

## Constraints
- `word_count` must not exceed 1500 (soft cap — efficiency pressure).
- If an iteration both decreases `word_count` AND maintains or increases `accuracy`, it's a strong keep.

## Guard
None yet — the benchmark itself is the guard.

## Strategy Notes
- Start sparse; iterate by reading failures from `tests/bench-prompt-assistant.sh` output and patching SKILL.md.
- Watch for assertions that are unreachable with the current template design — if a pattern can never match cleanly, revise the assertion rather than twisting the skill.
- User's invocation pattern is "work on this repo and brainstorm for X feature" — this should remain a first-class trigger.

## Runs
See `autoresearch.jsonl`.
