#!/usr/bin/env bash
# Adherence eval — A/B test bare vs <important if>-wrapped rules
# Toggles rules/*.md between "bare" and "wrapped" state, runs each scenario
# through `claude -p`, grades with regex.
#
# Usage: bash tests/bench-adherence.sh [--dry-run]
#
# Produces: tests/adherence-results/<timestamp>/{bare,wrapped}/<scenario>.txt
#           tests/adherence-results/<timestamp>/summary.tsv

set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCENARIOS="$REPO/tests/adherence-scenarios.tsv"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$REPO/tests/adherence-results/$TS"
DRY_RUN="${1:-}"

mkdir -p "$OUT/bare" "$OUT/wrapped"

CODING="$REPO/rules/coding-discipline.md"
ROUTING="$REPO/rules/routing-guardrails.md"

# Snapshot current state (the wrapped version is checked in)
cp "$CODING" "$OUT/coding-wrapped.md.bak"
cp "$ROUTING" "$OUT/routing-wrapped.md.bak"

# Safety: always restore wrapped on exit/crash
restore() {
  cp "$OUT/coding-wrapped.md.bak" "$CODING" 2>/dev/null
  cp "$OUT/routing-wrapped.md.bak" "$ROUTING" 2>/dev/null
}
trap restore EXIT INT TERM

# Build bare versions by stripping <important if> and </important> tag lines
strip_wrappers() {
  grep -v '^<important if=' | grep -v '^</important>'
}

mkdir -p "$OUT/_bare"
strip_wrappers < "$CODING" > "$OUT/_bare/coding-discipline.md"
strip_wrappers < "$ROUTING" > "$OUT/_bare/routing-guardrails.md"

run_scenarios() {
  local label="$1"  # "bare" or "wrapped"
  local n=0
  while IFS=$'\t' read -r rule type prompt expected forbidden; do
    # skip comments and empty lines
    [[ "$rule" =~ ^# ]] && continue
    [[ -z "$rule" ]] && continue
    n=$((n+1))
    local tag="${n}-${rule}-${type}"
    local out="$OUT/$label/$tag.txt"
    echo "[$label] $tag" >&2
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
      echo "DRY: would run: $prompt" > "$out"
    else
      # Run from repo root so rules auto-load
      (cd "$REPO" && echo "$prompt" | claude -p 2>&1) > "$out" || echo "[ERROR]" >> "$out"
    fi
  done < "$SCENARIOS"
  echo "$n"
}

grade() {
  local label="$1"
  local summary="$OUT/summary-$label.tsv"
  echo -e "rule\ttype\texpected_match\tforbidden_match\tverdict" > "$summary"
  local n=0 pass=0
  while IFS=$'\t' read -r rule type prompt expected forbidden; do
    [[ "$rule" =~ ^# ]] && continue
    [[ -z "$rule" ]] && continue
    n=$((n+1))
    local tag="${n}-${rule}-${type}"
    local out="$OUT/$label/$tag.txt"
    local em fm verdict
    if grep -qiE "$expected" "$out" 2>/dev/null; then em="YES"; else em="no"; fi
    if grep -qiE "$forbidden" "$out" 2>/dev/null; then fm="YES"; else fm="no"; fi
    if [[ "$type" == "positive" ]]; then
      if [[ "$em" == "YES" && "$fm" == "no" ]]; then verdict="PASS"; pass=$((pass+1)); else verdict="FAIL"; fi
    else
      # negative: forbidden must NOT match
      if [[ "$fm" == "no" ]]; then verdict="PASS"; pass=$((pass+1)); else verdict="FAIL"; fi
    fi
    echo -e "${rule}\t${type}\t${em}\t${fm}\t${verdict}" >> "$summary"
  done < "$SCENARIOS"
  echo "$pass/$n"
}

# --- RUN BARE CONDITION ---
echo "=== Running bare condition ==="
cp "$OUT/_bare/coding-discipline.md" "$CODING"
cp "$OUT/_bare/routing-guardrails.md" "$ROUTING"
BARE_N=$(run_scenarios bare)

# --- RUN WRAPPED CONDITION ---
echo "=== Running wrapped condition ==="
cp "$OUT/coding-wrapped.md.bak" "$CODING"
cp "$OUT/routing-wrapped.md.bak" "$ROUTING"
WRAPPED_N=$(run_scenarios wrapped)

# --- ALWAYS restore wrapped (the checked-in state) ---
cp "$OUT/coding-wrapped.md.bak" "$CODING"
cp "$OUT/routing-wrapped.md.bak" "$ROUTING"

# --- GRADE ---
BARE_PASS=$(grade bare)
WRAPPED_PASS=$(grade wrapped)

# --- REPORT ---
{
  echo "# Adherence eval — $TS"
  echo ""
  echo "| condition | pass |"
  echo "|---|---|"
  echo "| bare     | $BARE_PASS |"
  echo "| wrapped  | $WRAPPED_PASS |"
  echo ""
  echo "## Per-scenario verdicts"
  echo ""
  echo "| rule | type | bare | wrapped |"
  echo "|---|---|---|---|"
  paste <(tail -n +2 "$OUT/summary-bare.tsv") <(tail -n +2 "$OUT/summary-wrapped.tsv") | \
    awk -F'\t' '{printf "| %s | %s | %s | %s |\n", $1, $2, $5, $10}'
} > "$OUT/report.md"

cat "$OUT/report.md"
echo ""
echo "Full outputs in: $OUT"
