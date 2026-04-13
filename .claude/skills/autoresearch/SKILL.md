---
name: autoresearch
description: Autonomous goal-directed iteration loop. Set a goal, define a metric, and let the agent experiment indefinitely — modify, benchmark, keep or discard, repeat. Works for any optimization target (test coverage, bundle size, performance, syntax minimality, code quality, LLM training loss). Triggers on "autoresearch", "optimize this", "run experiments on", "improve X metric", "autonomous iteration", "hill-climb", "experiment loop". Use /autoresearch to start a new session or resume an existing one. Use /autoresearch:plan to interactively define the goal before starting.
---

# Autoresearch — Autonomous Goal-directed Iteration

Try an idea → measure it → keep what works → discard what doesn't → repeat forever.

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch). Applies constraint-driven autonomous iteration to any domain with a measurable metric.

## Core Loop

```
LOOP (forever or N iterations):
  1. Read state — git log, autoresearch.jsonl, autoresearch.md
  2. Pick next change — based on what worked, what failed, what's untried
  3. Make ONE focused change
  4. Git commit (before verification)
  5. Run benchmark: bash autoresearch.sh
  6. Parse METRIC lines from output
  7. If improved → keep. If worse → git revert. If crashed → fix or skip.
  8. Append result to autoresearch.jsonl
  9. Update autoresearch.md with learnings
  10. Repeat — never stop until interrupted or N iterations complete.
```

## Commands

| Command | Purpose |
|---------|---------|
| `/autoresearch` | Start or resume the autonomous loop |
| `/autoresearch:plan` | Interactive setup wizard — build config from a goal |

## Setup Phase

Before looping, perform a one-time setup. If `autoresearch.md` already exists, skip to **Resume**.

### New Session

Collect from the user (ask via questions, batch 2-3 at a time):

1. **Goal** — what to optimize (e.g., "increase test coverage", "minimize keyword count")
2. **Metric** — the number to track, extracted from benchmark output (e.g., `coverage`, `keywords`, `val_bpb`)
3. **Direction** — `higher` or `lower` is better
4. **Scope** — which files can be modified vs read-only
5. **Verify command** — how to measure (becomes `autoresearch.sh`)
6. **Constraints** — metrics that must NOT regress (optional)
7. **Guard** — command that must always pass, e.g., `npm test` (optional)

Then:

1. Create branch: `git checkout -b autoresearch/<tag>` (tag = short slug from goal)
2. Write `autoresearch.md` — see `references/session-files.md`
3. Write `autoresearch.sh` — see `references/session-files.md`
4. Optionally write `autoresearch.checks.sh` for guard checks
5. Run baseline: `bash autoresearch.sh`, record as run 0 in `autoresearch.jsonl`
6. Confirm setup with user, then begin the loop

### Resume

If `autoresearch.md` and `autoresearch.jsonl` exist:

1. Read both files for full context
2. Read recent git log on the autoresearch branch
3. Continue from last run number
4. Announce: "Resuming autoresearch — N runs so far, best metric: X"

## The Experiment Loop

Read `references/experiment-loop.md` for the full protocol. Key rules:

1. **One change per iteration** — atomic. If it breaks, you know exactly why.
2. **Mechanical verification only** — no subjective judgment. Numbers only.
3. **Automatic rollback** — failed changes revert instantly via `git revert` or `git reset`.
4. **Simplicity wins** — equal results + less code = KEEP. Deleting code that doesn't help = great outcome.
5. **Git is memory** — every experiment committed. Agent reads git log + diff before each iteration.
6. **Never stop** — do not ask "should I continue?" The human may be asleep. Run until interrupted or N iterations complete.
7. **When stuck, think harder** — re-read context, combine near-misses, try radical changes, read papers referenced in code.
8. **Read before write** — understand full context before modifying anything.

## Benchmark Script Convention

`autoresearch.sh` must output metrics as `METRIC name=value` lines on stdout:

```bash
#!/usr/bin/env bash
set -euo pipefail
# ... run workload ...
echo "METRIC coverage=87.3"
echo "METRIC total_funcs=219"
```

The primary metric (from config) determines keep/discard. Additional metrics are logged for context.

## Result Logging

Append one JSON line per run to `autoresearch.jsonl`:

```json
{"run":1,"commit":"a1b2c3d","metrics":{"coverage":87.3,"total_funcs":219},"status":"keep","description":"add edge case tests for auth module","timestamp":1742918400}
```

Fields: `run` (sequential), `commit` (short hash), `metrics` (object), `status` (`keep`|`discard`|`crash`|`checks_failed`), `description` (what was tried), `timestamp` (unix seconds).

## Confidence Scoring

Requires python3 for the MAD calculation (`scripts/confidence.sh`). After 3+ runs, compute confidence using Median Absolute Deviation (MAD):

- `confidence = |best_improvement| / MAD`
- ≥2.0× = likely real improvement
- 1.0–2.0× = above noise but marginal
- <1.0× = within noise — consider re-running

Report confidence in loop output. Advisory only — never auto-discard based on it.

## Progress Reporting

Every 5 iterations, print a summary:

```
── Autoresearch Progress (runs 1-5) ──
Best: coverage=89.0 (run 6, +3.8 from baseline)
Kept: 4 | Discarded: 1 | Crashed: 0
Last 3: +2.1 (keep), -0.3 (discard), +0.7 (keep)
Confidence: 3.2× (likely real)
```

## Bounded vs Unbounded

- Default: unbounded (loop forever)
- User can specify `Iterations: N` — run exactly N iterations, then print final summary
- Final summary includes: baseline → best, total kept/discarded/crashed, top 3 improvements

## Guard Checks

If `autoresearch.checks.sh` exists or user specified a Guard command:

- Run after every passing benchmark
- If guard fails → status = `checks_failed`, revert changes
- Guard files are never modified by the agent
- Up to 2 rework attempts before giving up on that experiment

## Finalization

When the user asks to finalize (or after bounded loop completes):

1. Print final summary with baseline → best metric
2. List all kept changes with their improvements
3. Suggest: merge branch, cherry-pick best changes, or continue iterating
