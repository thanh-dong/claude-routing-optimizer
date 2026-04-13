# Autoresearch: Routing Accuracy

## Config
- **Benchmark**: `bash autoresearch.sh`
- **Target metric**: `accuracy` (higher is better, max 100)
- **Secondary metric**: `tokens` (lower is better, target <1000)
- **Scope**: `~/.claude/CLAUDE.md` (generated routing guide) + `tests/routing-assertions.txt`
- **Branch**: `autoresearch/routing-accuracy`
- **Started**: 2026-04-13T00:00:00Z

## Goal
Maximize the percentage of routing assertions that pass against the generated CLAUDE.md. Each assertion encodes a correct routing decision (condition X -> tool Y) or a correctness constraint (condition X should NOT route to tool Z).

## Stop Conditions
- `accuracy` = 100 AND `tokens` < 1000: DONE (perfect)
- `accuracy` = 100 AND `tokens` >= 1000: switch to token compression goal
- 5 consecutive runs with no accuracy improvement: STOP and reassess strategy

## Rules
1. One change per experiment (modify CLAUDE.md OR assertions, not both in same run)
2. Run benchmark after every change
3. Keep if accuracy improves (or stays equal with fewer tokens)
4. Discard if accuracy regresses
5. Log every run to autoresearch.jsonl
6. Commit kept changes with `Result:` trailer

## Strategy
Priority order:
1. Fix failing positive assertions (missing routing rules) — biggest accuracy gain
2. Fix failing negative assertions (rules that shouldn't be there)
3. Compress passing sections to reduce tokens without losing assertions
4. Add new assertions for uncovered edge cases (increases total, may temporarily drop %)
5. Refine assertion patterns if they're too brittle or too loose

## What to change
- **To improve accuracy**: Edit `~/.claude/CLAUDE.md` to add/fix routing rules
- **To improve test coverage**: Edit `tests/routing-assertions.txt` to add new assertions
- **To improve tokens**: Rewrite CLAUDE.md sections more concisely
- **After improving SKILL.md**: Re-run `/optimize-routing` to regenerate CLAUDE.md, then benchmark
