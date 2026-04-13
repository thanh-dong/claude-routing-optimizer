# Session Files

Two files keep the session alive across restarts and context resets. A fresh agent with no memory can read these and continue exactly where the previous session left off.

## autoresearch.md

Living document — the session's brain. Created once during setup, updated throughout.

### Template

```markdown
# Autoresearch: <Goal Title>

## Config
- **Benchmark**: `bash autoresearch.sh`
- **Target metric**: `<metric_name>` (<higher|lower> is better)
- **Constraint**: `<constraint_metric>` must stay <at|above|below> <value> (optional)
- **Scope**: <files/directories the agent may modify>
- **Guard**: `<guard_command>` (optional)
- **Branch**: `autoresearch/<tag>`
- **Started**: <ISO-8601 timestamp>

## Goal
<1-3 sentences describing the objective and why it matters>

## Rules
1. One change per experiment
2. Run benchmark after every change
3. Keep if target metric improves (and constraints hold), discard otherwise
4. Log every run to autoresearch.jsonl
5. Commit kept changes with `Result:` trailer in commit message

## Stop Conditions
<When to stop automatically. Examples: "accuracy=100", "5 runs with no improvement", "N iterations reached">

## Strategy
<Priority order for maximum gain. Updated as the agent learns what works.>

## What's Been Tried
<Updated after each batch of experiments. Summarize approaches, not individual runs.>

## Dead Ends
<Approaches confirmed not to work. Prevents re-trying failed ideas.>

## Key Wins
<Significant improvements worth noting. Include run # and delta.>
```

### Update Rules

- **Strategy**: Update when the agent discovers a new priority order or approach
- **What's Been Tried**: Update every 5-10 runs with a summary
- **Dead Ends**: Add immediately when an approach is confirmed dead
- **Key Wins**: Add when a run produces notably good results

Keep it concise. This file is read at the start of every session — bloat wastes tokens.

## autoresearch.sh

Benchmark script. Must be executable (`chmod +x`). Must output `METRIC name=value` lines on stdout.

### Requirements

1. Exit 0 on success, non-zero on failure
2. Output one or more `METRIC name=value` lines to stdout
3. The primary metric (from config) must always be present
4. Additional metrics are optional context
5. Must be reproducible — same code should produce similar results
6. Should complete in a reasonable time (define "reasonable" per domain)

### Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# ---- Pre-checks (fail fast) ----
# e.g., verify dependencies exist, files in place

# ---- Run workload ----
# e.g., run tests, build, train, benchmark

# ---- Extract and output metrics ----
echo "METRIC primary_metric=$VALUE"
echo "METRIC secondary_metric=$VALUE"  # optional
```

### Examples

**Test coverage:**
```bash
#!/usr/bin/env bash
set -euo pipefail
OUTPUT=$(go test ./... -coverprofile=cover.out 2>&1)
COVERAGE=$(go tool cover -func=cover.out | grep total | awk '{print $3}' | tr -d '%')
FUNCS_100=$(go tool cover -func=cover.out | awk '$3 == "100.0%" {n++} END {print n+0}')
TOTAL_FUNCS=$(go tool cover -func=cover.out | wc -l | tr -d ' ')
echo "METRIC coverage=$COVERAGE"
echo "METRIC funcs_at_100=$FUNCS_100"
echo "METRIC total_funcs=$TOTAL_FUNCS"
```

**Keyword minimality:**
```bash
#!/usr/bin/env bash
set -euo pipefail
KEYWORD_COUNT=$(grep -c '.' keywords.txt 2>/dev/null || echo 0)
COVERAGE=$(grep -oP 'P\d+' candidate.yaml | sort -u | wc -l)
echo "METRIC keywords=$KEYWORD_COUNT"
echo "METRIC coverage=$COVERAGE"
```

**Bundle size:**
```bash
#!/usr/bin/env bash
set -euo pipefail
npm run build --silent
SIZE_KB=$(du -sk dist/ | awk '{print $1}')
echo "METRIC bundle_size_kb=$SIZE_KB"
```

**LLM training (fixed time budget):**
```bash
#!/usr/bin/env bash
set -euo pipefail
uv run train.py > run.log 2>&1
VAL_BPB=$(grep "^val_bpb:" run.log | awk '{print $2}')
VRAM=$(grep "^peak_vram_mb:" run.log | awk '{print $2}')
echo "METRIC val_bpb=$VAL_BPB"
echo "METRIC peak_vram_mb=$VRAM"
```

## autoresearch.checks.sh (optional)

Guard script. Runs after every passing benchmark. If it exits non-zero, the experiment is marked `checks_failed` and reverted.

```bash
#!/usr/bin/env bash
set -euo pipefail
npm test --run
npm run typecheck
```

## autoresearch.jsonl

Append-only log. One JSON line per run. Never edited — only appended.

### Schema

```json
{
  "run": 1,
  "commit": "a1b2c3d",
  "metrics": {"coverage": 87.3, "total_funcs": 219},
  "status": "keep",
  "description": "add edge case tests for auth module",
  "timestamp": 1742918400
}
```

### Status Values

| Status | Meaning |
|--------|---------|
| `keep` | Metric improved, change kept |
| `discard` | Metric regressed or unchanged, change reverted |
| `crash` | Benchmark failed to run |
| `checks_failed` | Benchmark passed but guard check failed, change reverted |

### Commit Convention

Kept changes use this commit message format:

```
autoresearch: <short description>

Result: <metric>=<value> (delta: <+/-change>)
Run: <run_number>
```
