#!/usr/bin/env bash
set -uo pipefail

# Autoresearch benchmark: routing accuracy + token efficiency
# Checks routing assertions against ~/.claude/CLAUDE.md

CLAUDE_MD="${CLAUDE_MD:-$HOME/.claude/CLAUDE.md}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSERTIONS="$SCRIPT_DIR/routing-assertions.txt"
PASS=0
FAIL=0
TOTAL=0
FAILURES=""

if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "ERROR: $CLAUDE_MD not found"
    exit 1
fi

if [[ ! -f "$ASSERTIONS" ]]; then
    echo "ERROR: $ASSERTIONS not found"
    exit 1
fi

while IFS='|' read -r type pattern desc; do
    # Skip comments and blank lines
    [[ "$type" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$type" ]] && continue

    # Trim whitespace
    type="$(echo "$type" | tr -d '[:space:]')"
    pattern="$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    TOTAL=$((TOTAL + 1))

    if [[ "$type" == "+" ]]; then
        # Positive: pattern MUST match
        if grep -qiE "$pattern" "$CLAUDE_MD"; then
            PASS=$((PASS + 1))
        else
            FAIL=$((FAIL + 1))
            FAILURES="${FAILURES}  FAIL [+]: ${desc} (missing: ${pattern})\n"
        fi
    elif [[ "$type" == "-" ]]; then
        # Negative: pattern must NOT match
        if ! grep -qiE "$pattern" "$CLAUDE_MD"; then
            PASS=$((PASS + 1))
        else
            FAIL=$((FAIL + 1))
            FAILURES="${FAILURES}  FAIL [-]: ${desc} (found but shouldn't: ${pattern})\n"
        fi
    fi
done < "$ASSERTIONS"

# Token estimate (chars / 4)
CHARS=$(wc -c < "$CLAUDE_MD" | tr -d ' ')
TOKENS=$((CHARS / 4))

# Line count
LINES=$(wc -l < "$CLAUDE_MD" | tr -d ' ')

# Accuracy percentage
if [[ $TOTAL -gt 0 ]]; then
    ACCURACY=$((PASS * 100 / TOTAL))
else
    ACCURACY=0
fi

# Output failures for debugging
if [[ -n "$FAILURES" ]]; then
    echo "--- Failures ---"
    echo -e "$FAILURES"
fi

# Metrics (autoresearch reads these)
echo "METRIC accuracy=$ACCURACY"
echo "METRIC pass=$PASS"
echo "METRIC fail=$FAIL"
echo "METRIC total=$TOTAL"
echo "METRIC tokens=$TOKENS"
echo "METRIC lines=$LINES"
