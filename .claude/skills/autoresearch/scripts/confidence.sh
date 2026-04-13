#!/usr/bin/env bash
# Calculate confidence score from autoresearch.jsonl
# Usage: bash confidence.sh <metric_name> <direction> [jsonl_file]
# direction: "higher" or "lower"
# Output: confidence score (float) and interpretation
#
# Uses Median Absolute Deviation (MAD) as robust noise estimator.
# Confidence = |best_improvement| / MAD
# ≥2.0 = likely real, 1.0-2.0 = marginal, <1.0 = within noise

set -euo pipefail

METRIC="${1:?Usage: confidence.sh <metric> <direction> [jsonl_file]}"
DIRECTION="${2:?Usage: confidence.sh <metric> <direction> [jsonl_file]}"
JSONL="${3:-autoresearch.jsonl}"

if [ ! -f "$JSONL" ]; then
  echo "CONFIDENCE: N/A (no jsonl file)"
  exit 0
fi

# Extract metric values from kept runs (need python/awk for math)
python3 -c "
import json, sys, statistics

metric = '$METRIC'
direction = '$DIRECTION'

values = []
with open('$JSONL') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            if metric in entry.get('metrics', {}):
                values.append(float(entry['metrics'][metric]))
        except (json.JSONDecodeError, ValueError):
            continue

if len(values) < 3:
    print(f'CONFIDENCE: N/A (need 3+ runs, have {len(values)})')
    sys.exit(0)

baseline = values[0]
if direction == 'higher':
    best_improvement = max(values) - baseline
else:
    best_improvement = baseline - min(values)

median_val = statistics.median(values)
deviations = [abs(v - median_val) for v in values]
mad = statistics.median(deviations)

if mad == 0:
    if best_improvement > 0:
        print(f'CONFIDENCE: inf (zero noise, improvement={best_improvement:.4f})')
    else:
        print(f'CONFIDENCE: 0.0 (zero noise, no improvement)')
    sys.exit(0)

confidence = abs(best_improvement) / mad

if confidence >= 2.0:
    label = 'likely real'
elif confidence >= 1.0:
    label = 'above noise but marginal'
else:
    label = 'within noise'

print(f'CONFIDENCE: {confidence:.1f}x ({label})')
print(f'  best_improvement={best_improvement:.4f} mad={mad:.4f}')
" 2>&1
