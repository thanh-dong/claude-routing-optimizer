#!/usr/bin/env bash
set -uo pipefail

# Autoresearch benchmark: SKILL.md effectiveness
# Uses § as field delimiter (pipe conflicts with regex alternation)
# Compatible with bash 3.2+ (macOS)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"
ASSERTIONS="$SCRIPT_DIR/skill-effectiveness-assertions.txt"

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

p1_pass=0; p1_fail=0
p2_pass=0; p2_fail=0
p3_pass=0; p3_fail=0
p4_pass=0; p4_fail=0
p5_pass=0; p5_fail=0
cx_pass=0; cx_fail=0

current_phase="unknown"

if [[ ! -f "$ASSERTIONS" ]]; then
    echo "ERROR: $ASSERTIONS not found"
    exit 1
fi

inc_pass() {
    case "$current_phase" in
        p1) p1_pass=$((p1_pass + 1)) ;; p2) p2_pass=$((p2_pass + 1)) ;;
        p3) p3_pass=$((p3_pass + 1)) ;; p4) p4_pass=$((p4_pass + 1)) ;;
        p5) p5_pass=$((p5_pass + 1)) ;; cx) cx_pass=$((cx_pass + 1)) ;;
    esac
}

inc_fail() {
    case "$current_phase" in
        p1) p1_fail=$((p1_fail + 1)) ;; p2) p2_fail=$((p2_fail + 1)) ;;
        p3) p3_fail=$((p3_fail + 1)) ;; p4) p4_fail=$((p4_fail + 1)) ;;
        p5) p5_fail=$((p5_fail + 1)) ;; cx) cx_fail=$((cx_fail + 1)) ;;
    esac
}

while IFS='§' read -r type filepath pattern desc; do
    # Track phase from section headers
    if [[ "$type" =~ PHASE\ 1 ]]; then current_phase="p1"; continue; fi
    if [[ "$type" =~ PHASE\ 2 ]]; then current_phase="p2"; continue; fi
    if [[ "$type" =~ PHASE\ 3 ]]; then current_phase="p3"; continue; fi
    if [[ "$type" =~ PHASE\ 4 ]]; then current_phase="p4"; continue; fi
    if [[ "$type" =~ PHASE\ 5 ]]; then current_phase="p5"; continue; fi
    if [[ "$type" =~ CROSS-PHASE ]]; then current_phase="cx"; continue; fi

    # Skip comments and blank lines
    [[ "$type" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$type" ]] && continue

    type="$(echo "$type" | tr -d '[:space:]')"
    filepath="$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    pattern="$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    full_path="$PROJECT_DIR/$filepath"

    if [[ ! -f "$full_path" ]]; then
        TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); inc_fail
        FAILURES="${FAILURES}  FAIL [!]: ${desc} (file not found)\n"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    if [[ "$type" == "+" ]]; then
        if grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1)); inc_pass
        else
            FAIL=$((FAIL + 1)); inc_fail
            FAILURES="${FAILURES}  FAIL [+]: ${desc}\n"
        fi
    elif [[ "$type" == "-" ]]; then
        if ! grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1)); inc_pass
        else
            FAIL=$((FAIL + 1)); inc_fail
            FAILURES="${FAILURES}  FAIL [-]: ${desc}\n"
        fi
    fi
done < "$ASSERTIONS"

if [[ $TOTAL -gt 0 ]]; then ACCURACY=$((PASS * 100 / TOTAL)); else ACCURACY=0; fi

if [[ -n "$FAILURES" ]]; then
    echo "--- Failures ---"
    echo -e "$FAILURES"
fi

echo "--- By Phase ---"
for phase in p1 p2 p3 p4 p5 cx; do
    case "$phase" in
        p1) p=$p1_pass; f=$p1_fail; label="Phase 1 (Inventory)" ;;
        p2) p=$p2_pass; f=$p2_fail; label="Phase 2 (Overlap)" ;;
        p3) p=$p3_pass; f=$p3_fail; label="Phase 3 (Generate)" ;;
        p4) p=$p4_pass; f=$p4_fail; label="Phase 4 (Verify)" ;;
        p5) p=$p5_pass; f=$p5_fail; label="Phase 5 (Report)" ;;
        cx) p=$cx_pass; f=$cx_fail; label="Cross-Phase" ;;
    esac
    t=$((p + f))
    if [[ $t -gt 0 ]]; then pct=$((p * 100 / t)); else pct=0; fi
    echo "  $label: $p/$t ($pct%)"
done

echo ""
echo "METRIC accuracy=$ACCURACY"
echo "METRIC pass=$PASS"
echo "METRIC fail=$FAIL"
echo "METRIC total=$TOTAL"
echo "METRIC phase1=${p1_pass}/$((p1_pass + p1_fail))"
echo "METRIC phase2=${p2_pass}/$((p2_pass + p2_fail))"
echo "METRIC phase3=${p3_pass}/$((p3_pass + p3_fail))"
echo "METRIC phase4=${p4_pass}/$((p4_pass + p4_fail))"
echo "METRIC phase5=${p5_pass}/$((p5_pass + p5_fail))"
echo "METRIC crossphase=${cx_pass}/$((cx_pass + cx_fail))"
