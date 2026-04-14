#!/usr/bin/env bash
set -uo pipefail

# Autoresearch benchmark: skillset quality & portability
# Checks quality assertions against project files
# Compatible with bash 3.2+ (macOS default)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"
ASSERTIONS="$SCRIPT_DIR/quality-assertions.txt"

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

# Dimension counters (bash 3 compatible)
port_pass=0; port_fail=0
comp_pass=0; comp_fail=0
clar_pass=0; clar_fail=0
robu_pass=0; robu_fail=0
cons_pass=0; cons_fail=0

current_dim="unknown"

if [[ ! -f "$ASSERTIONS" ]]; then
    echo "ERROR: $ASSERTIONS not found"
    exit 1
fi

inc_pass() {
    case "$current_dim" in
        portability)  port_pass=$((port_pass + 1)) ;;
        completeness) comp_pass=$((comp_pass + 1)) ;;
        clarity)      clar_pass=$((clar_pass + 1)) ;;
        robustness)   robu_pass=$((robu_pass + 1)) ;;
        consistency)  cons_pass=$((cons_pass + 1)) ;;
    esac
}

inc_fail() {
    case "$current_dim" in
        portability)  port_fail=$((port_fail + 1)) ;;
        completeness) comp_fail=$((comp_fail + 1)) ;;
        clarity)      clar_fail=$((clar_fail + 1)) ;;
        robustness)   robu_fail=$((robu_fail + 1)) ;;
        consistency)  cons_fail=$((cons_fail + 1)) ;;
    esac
}

while IFS='|' read -r type filepath pattern desc; do
    # Track dimension from section headers
    if [[ "$type" =~ PORTABILITY ]]; then current_dim="portability"; continue; fi
    if [[ "$type" =~ COMPLETENESS ]]; then current_dim="completeness"; continue; fi
    if [[ "$type" =~ CLARITY ]]; then current_dim="clarity"; continue; fi
    if [[ "$type" =~ ROBUSTNESS ]]; then current_dim="robustness"; continue; fi
    if [[ "$type" =~ CONSISTENCY ]]; then current_dim="consistency"; continue; fi

    # Skip comments and blank lines
    [[ "$type" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$type" ]] && continue

    # Trim whitespace
    type="$(echo "$type" | tr -d '[:space:]')"
    filepath="$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    pattern="$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    full_path="$PROJECT_DIR/$filepath"

    if [[ ! -f "$full_path" ]]; then
        TOTAL=$((TOTAL + 1))
        FAIL=$((FAIL + 1))
        inc_fail
        FAILURES="${FAILURES}  FAIL [!]: ${desc} (file not found: ${filepath})\n"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    if [[ "$type" == "+" ]]; then
        if grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1))
            inc_pass
        else
            FAIL=$((FAIL + 1))
            inc_fail
            FAILURES="${FAILURES}  FAIL [+]: ${desc} (missing in ${filepath})\n"
        fi
    elif [[ "$type" == "-" ]]; then
        if ! grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1))
            inc_pass
        else
            FAIL=$((FAIL + 1))
            inc_fail
            FAILURES="${FAILURES}  FAIL [-]: ${desc} (found in ${filepath})\n"
        fi
    fi
done < "$ASSERTIONS"

# Accuracy
if [[ $TOTAL -gt 0 ]]; then
    ACCURACY=$((PASS * 100 / TOTAL))
else
    ACCURACY=0
fi

# Output failures
if [[ -n "$FAILURES" ]]; then
    echo "--- Failures ---"
    echo -e "$FAILURES"
fi

# Dimension breakdown
echo "--- By Dimension ---"
for dim in portability completeness clarity robustness consistency; do
    case "$dim" in
        portability)  p=$port_pass; f=$port_fail ;;
        completeness) p=$comp_pass; f=$comp_fail ;;
        clarity)      p=$clar_pass; f=$clar_fail ;;
        robustness)   p=$robu_pass; f=$robu_fail ;;
        consistency)  p=$cons_pass; f=$cons_fail ;;
    esac
    t=$((p + f))
    if [[ $t -gt 0 ]]; then pct=$((p * 100 / t)); else pct=0; fi
    echo "  $dim: $p/$t ($pct%)"
done

# Metrics
echo ""
echo "METRIC accuracy=$ACCURACY"
echo "METRIC pass=$PASS"
echo "METRIC fail=$FAIL"
echo "METRIC total=$TOTAL"
echo "METRIC portability=${port_pass}/$((port_pass + port_fail))"
echo "METRIC completeness=${comp_pass}/$((comp_pass + comp_fail))"
echo "METRIC clarity=${clar_pass}/$((clar_pass + clar_fail))"
echo "METRIC robustness=${robu_pass}/$((robu_pass + robu_fail))"
echo "METRIC consistency=${cons_pass}/$((cons_pass + cons_fail))"
