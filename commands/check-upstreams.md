---
description: Check upstream sources tracked in UPSTREAM.tsv for new commits since adoption. Reports drift; with --apply, fetches file-port upstreams and shows diffs vs local.
---

# Check Upstream Adoptions

Verify that files this repo adopted from upstream sources are still in sync, and surface upstream changes since the recorded adoption date.

$ARGUMENTS

## Instructions

Follow the `check-upstreams` skill at `skills/check-upstreams/SKILL.md` exactly.

Execute all phases in order:
1. **Parse TSV** — read `UPSTREAM.tsv`, validate columns
2. **Query upstreams** — `gh api` for each row's latest commit (path-scoped)
3. **Classify drift** — current / drift-actionable / drift-review / gone / stable
4. **Report** — markdown table + per-row detail with compare URLs
5. **Apply** (if `--apply`) — fetch upstream file-ports into `/tmp/check-upstreams/`, print diffs vs local
6. **Update cache** (if `--update-cache`) — write back `upstream_last_sha` / `upstream_last_date`

Arguments:
- (no args) — dry-run, report only
- `add <ref>` — onboard a new adoption (GitHub URL, `owner/repo:path`, or `owner/repo`). Auto-fills SHA/date.
- `--apply` — fetch + diff for `file-port` rows with drift
- `--update-cache` — refresh cached upstream SHA/date columns in TSV

If `UPSTREAM.tsv` doesn't exist, the skill creates it and prints onboarding instructions instead of running the check.
