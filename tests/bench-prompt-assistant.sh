#!/usr/bin/env bash
set -o pipefail

# Autoresearch benchmark: prompt-assistant SKILL.md quality
# Assertion format: type§filepath§regex§description
#   + = file must match regex
#   - = file must NOT match regex
# Section headers lines starting with CATEGORY: set the category for grouping.
# Compatible with bash 3.2+ (macOS).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"
ASSERTIONS="$SCRIPT_DIR/prompt-assistant-assertions.txt"

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

declare -a CAT_NAMES CAT_PASS CAT_FAIL
current_cat="uncategorized"
current_idx=-1

find_cat_idx() {
    local name="$1"
    local i=0
    for n in "${CAT_NAMES[@]:-}"; do
        if [[ "$n" == "$name" ]]; then echo "$i"; return; fi
        i=$((i + 1))
    done
    CAT_NAMES[${#CAT_NAMES[@]}]="$name"
    CAT_PASS[${#CAT_PASS[@]}]=0
    CAT_FAIL[${#CAT_FAIL[@]}]=0
    echo $((${#CAT_NAMES[@]} - 1))
}

if [[ ! -f "$ASSERTIONS" ]]; then
    echo "ERROR: $ASSERTIONS not found"
    exit 1
fi

current_idx=$(find_cat_idx "uncategorized")

while IFS='§' read -r type filepath pattern desc; do
    # Category header: "CATEGORY: name"
    if [[ "$type" =~ ^CATEGORY: ]]; then
        cat_name="${type#CATEGORY:}"
        cat_name="$(echo "$cat_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        current_cat="$cat_name"
        current_idx=$(find_cat_idx "$cat_name")
        continue
    fi

    # Skip comments and blanks
    [[ "$type" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$type" ]] && continue

    type="$(echo "$type" | tr -d '[:space:]')"
    filepath="$(echo "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    pattern="$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    full_path="$PROJECT_DIR/$filepath"

    if [[ ! -f "$full_path" ]]; then
        TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
        CAT_FAIL[$current_idx]=$((${CAT_FAIL[$current_idx]} + 1))
        FAILURES="${FAILURES}  FAIL [!]: ${desc} (file not found)\n"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    if [[ "$type" == "+" ]]; then
        if grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1))
            CAT_PASS[$current_idx]=$((${CAT_PASS[$current_idx]} + 1))
        else
            FAIL=$((FAIL + 1))
            CAT_FAIL[$current_idx]=$((${CAT_FAIL[$current_idx]} + 1))
            FAILURES="${FAILURES}  FAIL [+] (${current_cat}): ${desc}\n"
        fi
    elif [[ "$type" == "-" ]]; then
        if ! grep -qiE "$pattern" "$full_path"; then
            PASS=$((PASS + 1))
            CAT_PASS[$current_idx]=$((${CAT_PASS[$current_idx]} + 1))
        else
            FAIL=$((FAIL + 1))
            CAT_FAIL[$current_idx]=$((${CAT_FAIL[$current_idx]} + 1))
            FAILURES="${FAILURES}  FAIL [-] (${current_cat}): ${desc}\n"
        fi
    fi
done < "$ASSERTIONS"

# Token-efficiency proxy: wc -w on SKILL.md. Lower is better (but don't go so low
# you drop required assertions). We log it; the primary metric is accuracy.
SKILL_FILE="$PROJECT_DIR/skills/prompt-assistant/SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
    WORDS=$(wc -w < "$SKILL_FILE" | tr -d ' ')
else
    WORDS=0
fi

if [[ $TOTAL -gt 0 ]]; then ACCURACY=$((PASS * 100 / TOTAL)); else ACCURACY=0; fi

if [[ -n "$FAILURES" ]]; then
    echo "--- Failures ---"
    echo -e "$FAILURES"
fi

echo "--- By Category ---"
i=0
for name in "${CAT_NAMES[@]:-}"; do
    p=${CAT_PASS[$i]}
    f=${CAT_FAIL[$i]}
    t=$((p + f))
    if [[ $t -gt 0 ]]; then
        pct=$((p * 100 / t))
        printf "  %-24s %d/%d (%d%%)\n" "$name" "$p" "$t" "$pct"
    fi
    i=$((i + 1))
done

echo ""
echo "METRIC accuracy=$ACCURACY"
echo "METRIC pass=$PASS"
echo "METRIC fail=$FAIL"
echo "METRIC total=$TOTAL"
echo "METRIC word_count=$WORDS"
