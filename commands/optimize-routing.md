---
description: Scan all installed plugins, detect overlaps, and regenerate ~/.claude/CLAUDE.md as an optimal routing guide. Run after adding/removing plugins.
---

# Optimize Plugin Routing

Run the full routing optimization pipeline. This scans all installed plugins, skills, agents, and commands, detects where multiple plugins overlap, and regenerates `~/.claude/CLAUDE.md` with optimal routing rules.

$ARGUMENTS

## Instructions

Follow the `optimize-routing` skill at `~/.claude/skills/optimize-routing/SKILL.md` exactly.

Execute all 5 phases in order:
1. **Inventory** — scan all installed plugins, enabled/disabled state, skills, agents, commands
2. **Overlap Detection** — group by task domain, find where 2+ plugins compete
3. **Generate CLAUDE.md** — write conditional routing rules and workflow chains (under 80 lines, under 1000 tokens)
4. **Verify** — check all referenced commands/agents exist, check token/line budget
5. **Report** — summarize what was found and changed

If arguments are provided, treat them as instructions:
- `--dry-run` — scan and report overlaps without writing CLAUDE.md
- `--verbose` — include per-plugin skill counts and full overlap analysis
- `--force` — overwrite CLAUDE.md even if no changes detected
