#!/usr/bin/env bash
set -uo pipefail

# Autoresearch benchmark: autoresearch skill effectiveness & safety
# Tests .claude/skills/autoresearch/ for accuracy, safety, robustness
# Compatible with bash 3.2+ (macOS)

PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
ASSERTIONS="tests/autoresearch-skill-assertions.txt"

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

# Category counters
core_pass=0; core_fail=0
setup_pass=0; setup_fail=0
resume_pass=0; resume_fail=0
safety_pass=0; safety_fail=0
exploop_pass=0; exploop_fail=0
sessfiles_pass=0; sessfiles_fail=0
scripts_pass=0; scripts_fail=0
final_pass=0; final_fail=0

current_cat="unknown"

if [[ ! -f "$ASSERTIONS" ]]; then
    echo "ERROR: $ASSERTIONS not found"
    exit 1
fi

inc_pass() {
    case "$current_cat" in
        core) core_pass=$((core_pass + 1)) ;; setup) setup_pass=$((setup_pass + 1)) ;;
        resume) resume_pass=$((resume_pass + 1)) ;; safety) safety_pass=$((safety_pass + 1)) ;;
        exploop) exploop_pass=$((exploop_pass + 1)) ;; sessfiles) sessfiles_pass=$((sessfiles_pass + 1)) ;;
        scripts) scripts_pass=$((scripts_pass + 1)) ;; final) final_pass=$((final_pass + 1)) ;;
    esac
}

inc_fail() {
    case "$current_cat" in
        core) core_fail=$((core_fail + 1)) ;; setup) setup_fail=$((setup_fail + 1)) ;;
        resume) resume_fail=$((resume_fail + 1)) ;; safety) safety_fail=$((safety_fail + 1)) ;;
        exploop) exploop_fail=$((exploop_fail + 1)) ;; sessfiles) sessfiles_fail=$((sessfiles_fail + 1)) ;;
        scripts) scripts_fail=$((scripts_fail + 1)) ;; final) final_fail=$((final_fail + 1)) ;;
    esac
}

while IFS='§' read -r type filepath pattern desc; do
    if [[ "$type" =~ CORE\ LOOP ]]; then current_cat="core"; continue; fi
    if [[ "$type" =~ SETUP ]]; then current_cat="setup"; continue; fi
    if [[ "$type" =~ RESUME ]]; then current_cat="resume"; continue; fi
    if [[ "$type" =~ SAFETY ]]; then current_cat="safety"; continue; fi
    if [[ "$type" =~ EXPERIMENT\ LOOP ]]; then current_cat="exploop"; continue; fi
    if [[ "$type" =~ SESSION\ FILES ]]; then current_cat="sessfiles"; continue; fi
    if [[ "$type" =~ SCRIPTS ]]; then current_cat="scripts"; continue; fi
    if [[ "$type" =~ FINALIZATION ]]; then current_cat="final"; continue; fi

    [[ "$type" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$type" ]] && continue

    type="$(echo "$type" | tr -d '[:space:]')"
    filepath="$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    pattern="$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    full_path="$PROJECT_DIR/$filepath"

    if [[ ! -f "$full_path" ]]; then
        TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); inc_fail
        FAILURES="${FAILURES}  FAIL [!]: ${desc} (file not found: ${filepath})\n"
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

echo "--- By Category ---"
for cat in core setup resume safety exploop sessfiles scripts final; do
    case "$cat" in
        core) p=$core_pass; f=$core_fail; label="Core Loop" ;;
        setup) p=$setup_pass; f=$setup_fail; label="Setup" ;;
        resume) p=$resume_pass; f=$resume_fail; label="Resume" ;;
        safety) p=$safety_pass; f=$safety_fail; label="Safety" ;;
        exploop) p=$exploop_pass; f=$exploop_fail; label="Experiment Loop" ;;
        sessfiles) p=$sessfiles_pass; f=$sessfiles_fail; label="Session Files" ;;
        scripts) p=$scripts_pass; f=$scripts_fail; label="Scripts" ;;
        final) p=$final_pass; f=$final_fail; label="Finalization" ;;
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
