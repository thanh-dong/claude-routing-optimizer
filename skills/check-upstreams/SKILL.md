---
name: check-upstreams
description: Use when checking whether upstream sources adopted in this repo have new changes since adoption. Reads UPSTREAM.tsv, queries GitHub for each row's latest commit, reports drift, and (with --apply) re-fetches file-port adoptions for review.
---

# check-upstreams

## Purpose

Detect drift between local adoptions (`rules/`, `skills/`) and their upstream sources tracked in `UPSTREAM.tsv`. Output a report; do not auto-merge.

## Inputs

- `UPSTREAM.tsv` at repo root (required). Columns:
  - `upstream_repo` — `owner/name` (GitHub)
  - `upstream_path` — file path within upstream repo, or `(repo concept)` for whole-repo inspiration
  - `local_path` — file we maintain
  - `adoption_type` — `file-port` | `technique` | `inspiration`
  - `adopted_sha` — upstream SHA at adoption (best-effort)
  - `adopted_date` — ISO date (YYYY-MM-DD)
  - `upstream_last_sha` — cached from prior run
  - `upstream_last_date` — cached from prior run
  - `notes` — free text

## Flags

- `--dry-run` (default) — fetch + report only, no TSV writeback
- `--update-cache` — refresh `upstream_last_sha` / `upstream_last_date` columns in TSV
- `--apply` — for `file-port` rows with drift, fetch upstream into `/tmp/check-upstreams/` and print a diff vs local. Never overwrites local automatically.

## Procedure

### Phase 0: Bootstrap

If `UPSTREAM.tsv` does not exist:
1. Write a header-only TSV:
   ```
   upstream_repo	upstream_path	local_path	adoption_type	adopted_sha	adopted_date	upstream_last_sha	upstream_last_date	notes
   ```
2. Print: `No adoptions tracked yet. Add one with: /check-upstreams add <github-url-or-owner/repo:path>`
3. Exit 0.

If invoked as `/check-upstreams add <ref>`, jump to **Phase A** below instead of Phase 1.

### Phase 1: Parse TSV

Read `UPSTREAM.tsv`. Skip header. For each non-blank row, split on tab. Validate 9 columns. Skip + warn malformed rows.

### Phase 2: Query upstreams

For each row, parallelize one of:

- `upstream_path` is a real path:
  ```
  gh api 'repos/{repo}/commits?path={path}&per_page=1'
  ```
- `upstream_path` starts with `(` (e.g. `(repo concept)`):
  ```
  gh api 'repos/{repo}/commits?per_page=1'
  ```

Extract `sha[:7]` and `commit.committer.date` (date portion only).

If repo returns 404, mark row `gone` and continue.

### Phase 3: Classify drift

For each row:

| Condition | Status |
|-----------|--------|
| `current_sha == adopted_sha` | `current` |
| `current_sha != adopted_sha` AND `adoption_type == file-port` | `drift-actionable` |
| `current_sha != adopted_sha` AND `adoption_type in {technique, inspiration}` | `drift-review` |
| upstream returned 404 | `gone` |
| TSV cache (`upstream_last_sha`) matches `current_sha` AND status was previously reported | `stable` |

### Phase 4: Report

Print a markdown table:

```
| Upstream | Local | Type | Adopted | Upstream Last | Status |
|----------|-------|------|---------|---------------|--------|
| ...      | ...   | ...  | YYYY-MM-DD (sha) | YYYY-MM-DD (sha) | drift-actionable |
```

Then per-row detail for any non-`current` row:
- `notes` from TSV
- For `drift-actionable`: link to upstream commit range (`https://github.com/{repo}/compare/{adopted_sha}...{current_sha}`)
- For `gone`: prompt user to update TSV or remove row

### Phase 4b: Schedule suggestion (first-run only)

After the report, if no scheduled routine for `/check-upstreams` exists (use `CronList` to verify), print exactly once:

```
Tip: schedule recurring drift checks with:
  /schedule create "weekly Mon 9am" "/check-upstreams"
```

Skip this block if a routine already exists, or if the report contained any `drift-actionable` / `gone` rows (don't add suggestions on top of action items).

### Phase 5 (if --apply): Show diffs for file-port drift

For each `drift-actionable` row:
1. `gh api 'repos/{repo}/contents/{path}' --jq .download_url` → curl into `/tmp/check-upstreams/{repo-slug}.upstream`
2. `diff -u {local_path} /tmp/check-upstreams/{repo-slug}.upstream` → print
3. Remind user: re-adoption is manual. Local may have intentional divergences (see `notes`).

### Phase 6 (if --update-cache): Write back TSV

For each row, update `upstream_last_sha` and `upstream_last_date` columns. Preserve other columns. Atomic write: temp file → rename.

Do NOT touch `adopted_sha` / `adopted_date` — those record the adoption event, not the latest check.

## Exit codes

- `0` — all `current` or `stable`
- `1` — one or more `drift-actionable`
- `2` — one or more `gone` (broken refs)
- `3` — TSV malformed or missing

Useful in CI: `bash check-upstreams.sh && echo green || echo "review needed"`.

## Phase A: `add` subcommand

Triggered by `/check-upstreams add <ref>`. Goal: append one row to `UPSTREAM.tsv` with the adoption SHA filled correctly, with minimum questions.

### A.1: Parse `<ref>`

Accept either form:
- GitHub blob URL: `https://github.com/{owner}/{repo}/blob/{branch}/{path}` → extract `{owner}/{repo}` and `{path}`
- Shorthand: `{owner}/{repo}:{path}` → split on `:`
- Repo-only (for inspiration): `{owner}/{repo}` → set `upstream_path = (repo concept)`

Reject anything else with: `Could not parse <ref>. Use a GitHub URL, owner/repo:path, or owner/repo for repo-level inspiration.`

### A.2: Verify upstream exists

```
gh api 'repos/{owner}/{repo}'
```

If 404, abort with the error.

### A.3: Capture current SHA + date

For path-scoped:
```
gh api 'repos/{owner}/{repo}/commits?path={path}&per_page=1'
```

For `(repo concept)`:
```
gh api 'repos/{owner}/{repo}/commits?per_page=1'
```

Extract `sha[:7]` and `committer.date` (YYYY-MM-DD only). These become both `adopted_sha`/`adopted_date` AND `upstream_last_sha`/`upstream_last_date` (current = adopted on the day we add).

### A.4: Ask exactly two questions

1. `local_path?` — relative path from repo root to the file we maintain. Validate it exists OR confirm the user wants to track an upcoming file.
2. `adoption_type?` — one of `file-port` / `technique` / `inspiration`. Default: `file-port` if `local_path` exists and is a single file we wrote.

### A.5: Quality gate

If `adoption_type ∈ {technique, inspiration}`:
- Require a `notes` value. Ask: `Why track this? (one line — what specifically did you borrow, and what would matter if upstream changed?)`
- Refuse empty / whitespace-only / "n/a"-style responses. The TSV is for actionable refs, not attribution dumps.

If `adoption_type == file-port`:
- `notes` is optional. If empty, leave blank.

### A.6: Append row

Append one tab-separated line to `UPSTREAM.tsv`. Print the appended row back to the user, then suggest:

```
Added. Verify with: /check-upstreams
```

## Adding adoptions manually (without the subcommand)

Same as Phase A but by hand:

1. Identify upstream `owner/name` and exact file path (or `(repo concept)` for inspiration-only).
2. Capture upstream SHA:
   ```
   gh api 'repos/{repo}/commits?path={path}&per_page=1' --jq '.[0].sha[0:7]'
   ```
3. Append a row to `UPSTREAM.tsv` with `adopted_sha` = captured SHA and `adopted_date` = today.
4. Mention upstream in the local file's frontmatter or a top comment, plus README's references list.

## Non-goals

- Auto-merging upstream changes (file-ports usually have intentional local edits — diffing is the right primitive).
- Tracking non-GitHub upstreams (would need provider-agnostic SHA/date extraction; out of scope).
- Notifications / scheduling — pair with `/loop` or `/schedule` if you want recurring checks.
