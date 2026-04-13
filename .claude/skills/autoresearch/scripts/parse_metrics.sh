#!/usr/bin/env bash
# Parse METRIC lines from autoresearch.sh output and format as JSON
# Usage: bash autoresearch.sh 2>&1 | bash parse_metrics.sh
# Output: {"coverage":87.3,"total_funcs":219}

set -euo pipefail

echo -n "{"
FIRST=true
while IFS= read -r line; do
  if [[ "$line" =~ ^METRIC[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=(.+)$ ]]; then
    NAME="${BASH_REMATCH[1]}"
    VALUE="${BASH_REMATCH[2]}"
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      echo -n ","
    fi
    # Check if value is numeric
    if [[ "$VALUE" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
      echo -n "\"$NAME\":$VALUE"
    else
      echo -n "\"$NAME\":\"$VALUE\""
    fi
  fi
done
echo "}"
