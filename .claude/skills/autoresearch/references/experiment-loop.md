# Experiment Loop Protocol

The complete step-by-step protocol for each iteration of the autoresearch loop.

## Before First Iteration

1. Read `autoresearch.md` — understand goal, metric, direction, scope, strategy
2. Read `autoresearch.jsonl` — know what's been tried and what worked
3. Read recent `git log --oneline -20` — understand recent changes
4. Read in-scope files for full context

## Each Iteration

### 1. Plan

Review state:
- What's the current best metric value?
- What approaches have been tried (from jsonl + git log)?
- What does the strategy section suggest trying next?
- Are there dead ends to avoid?

Pick ONE focused change. Prefer changes with high expected impact relative to complexity.

**Idea generation priority:**
1. Low-hanging fruit — obvious gaps, missing cases, simple fixes
2. Patterns from successful runs — what worked before? Can it be extended?
3. Inverses of failed runs — if adding X failed, does removing Y help?
4. Combinations — merge two near-miss approaches
5. Radical changes — different algorithm, architecture, or approach entirely
6. Literature/code review — read referenced docs, papers, or upstream code for ideas

### 2. Implement

Make exactly ONE change. Keep the diff small and reviewable.

- Modify only files within the declared scope
- Do not modify benchmark scripts or guard scripts
- Do not install new dependencies unless explicitly allowed

### 3. Commit

```bash
git add <changed-files-within-scope>
git commit -m "autoresearch: <short description of what this experiment tries>"
```

Only stage files within the declared scope. Never use blanket staging (`-A` or `.` flags) — these can stage secrets (.env), large files, or unrelated changes. Commit BEFORE running the benchmark. This makes revert clean.

### 4. Benchmark

```bash
bash autoresearch.sh 2>&1 | tee /tmp/autoresearch-output.txt
```

Parse `METRIC name=value` lines from the output. If no METRIC lines appear, treat as crash.

### 5. Guard Check (if configured)

If `autoresearch.checks.sh` exists:

```bash
bash autoresearch.checks.sh
```

If guard fails:
- Attempt to rework the change (up to 2 attempts)
- If still failing after rework, revert and log as `checks_failed`

### 6. Evaluate

Compare the primary metric against the current best:

- **Improved** (metric moved in the target direction):
  - Status: `keep`
  - The commit stays. This is now the new baseline.
- **Unchanged or regressed**:
  - Status: `discard`
  - Revert: `git revert HEAD --no-edit` or `git reset --hard HEAD~1`
- **Crashed** (benchmark didn't produce metrics):
  - If fixable (typo, import error): fix and re-run once
  - If fundamentally broken: `git reset --hard HEAD~1`, status: `crash`

**Constraint check:** If constraints are defined (e.g., "coverage must stay above 80"), verify them. If a constraint is violated even though the primary metric improved, treat as `discard`.

**Simplicity rule:** If the metric is unchanged but the code is simpler (fewer lines, removed dead code), that's a `keep`. Document as "simplification, metric unchanged."

### 7. Log

Append to `autoresearch.jsonl`:

```bash
echo '{"run":N,"commit":"HASH","metrics":{...},"status":"STATUS","description":"WHAT","timestamp":UNIX}' >> autoresearch.jsonl
```

### 8. Update Session Doc

Every 5-10 runs, update `autoresearch.md`:
- Add to **What's Been Tried** (summary, not per-run detail)
- Add to **Dead Ends** if an approach is confirmed dead
- Add to **Key Wins** if a notable improvement happened
- Revise **Strategy** if priorities have shifted

### 9. Progress Report

Every 5 iterations, output a progress summary:

```
── Autoresearch Progress (runs N-M) ──
Best: <metric>=<value> (run <N>, <delta> from baseline)
Kept: <n> | Discarded: <n> | Crashed: <n>
Last 3: <delta> (<status>), <delta> (<status>), <delta> (<status>)
Confidence: <score>× (<interpretation>)
```

### 10. Continue

Go to step 1. Do NOT ask the user if you should continue.

## Handling Edge Cases

### Stuck (no improvement for 5+ runs)

1. Re-read all in-scope files — something may have been missed
2. Review git log for patterns — what kind of changes worked?
3. Try combining two previously-kept changes in a new way
4. Try a radically different approach
5. Check if the benchmark itself has issues (flaky, wrong metric extraction)
6. Update strategy in autoresearch.md

### Flaky Benchmarks

If the same code produces different metric values on repeated runs:
- Run the benchmark 2-3 times and take the median
- Note the variance in the jsonl description
- Only keep changes with improvements larger than the observed noise

### Out of Scope Changes Needed

If progress requires changing files outside the declared scope:
- Note this in autoresearch.md under a new "Scope Expansion Needed" section
- Continue working within current scope
- The user will see this when they check in

### Large Refactors

If a valuable change requires touching many files:
- Break it into sequential atomic commits
- Each commit gets its own benchmark run
- If the intermediate state regresses but the final state improves, keep all commits as a group

## Timeout and Resource Limits

- If a benchmark run exceeds 2× the expected time, kill it and treat as crash
- If disk space or memory is becoming an issue, note it and continue with smaller experiments
- Monitor git branch size — if it's getting unwieldy, note it for the user
