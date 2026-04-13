# Claude Routing Optimizer

Auto-generate an optimal `~/.claude/CLAUDE.md` routing guide by scanning all installed Claude Code plugins, detecting overlaps, and writing conflict-resolution rules.

## Problem

When you install multiple Claude Code plugins (ECC, Impeccable, UI-UX-Pro-Max, Document-Skills, gstack, GitNexus, etc.), many skills overlap — 3+ plugins can do code review, 4+ can handle frontend design, multiple handle testing and debugging. Without routing guidance, Claude picks arbitrarily or uses the wrong tool.

A naive solution (listing every skill in CLAUDE.md) wastes thousands of tokens per session. The skill system already auto-triggers from description keywords — duplicating that in CLAUDE.md is pure overhead.

## Solution

This optimizer generates a **lean CLAUDE.md** (~740 tokens) that contains **only overlap resolution rules** — the one thing the skill system can't do on its own. It complements rather than duplicates.

## Installation

Copy the 3 files into your `~/.claude/` directory:

```bash
# Skill (the pipeline logic)
mkdir -p ~/.claude/skills/optimize-routing
cp skills/optimize-routing/SKILL.md ~/.claude/skills/optimize-routing/SKILL.md

# Command (slash command entry point)
cp commands/optimize-routing.md ~/.claude/commands/optimize-routing.md

# Rules (always-on quality guardrails)
cp rules/routing-guardrails.md ~/.claude/rules/routing-guardrails.md
cp rules/coding-discipline.md ~/.claude/rules/coding-discipline.md
```

Or clone and symlink:

```bash
git clone https://github.com/thanh-dong/claude-routing-optimizer.git ~/.claude/claude-routing-optimizer
ln -s ~/.claude/claude-routing-optimizer/skills/optimize-routing ~/.claude/skills/optimize-routing
ln -s ~/.claude/claude-routing-optimizer/commands/optimize-routing.md ~/.claude/commands/optimize-routing.md
ln -s ~/.claude/claude-routing-optimizer/rules/routing-guardrails.md ~/.claude/rules/routing-guardrails.md
ln -s ~/.claude/claude-routing-optimizer/rules/coding-discipline.md ~/.claude/rules/coding-discipline.md
```

## Usage

### Generate/regenerate routing guide

```
/optimize-routing
```

Run this after installing or removing any plugin. It will:
1. **Inventory** all installed plugins, skills, agents, commands
2. **Detect overlaps** where 2+ plugins compete for the same task domain
3. **Generate** `~/.claude/CLAUDE.md` with conditional routing rules and workflow chains
4. **Verify** all referenced commands/agents actually exist
5. **Report** summary of changes

### Options

```
/optimize-routing --dry-run    # Scan and report without writing
/optimize-routing --verbose    # Include per-plugin skill counts
/optimize-routing --force      # Overwrite even if no changes
```

## What Gets Generated

The output CLAUDE.md contains:
- **Overlap resolution blocks** — conditional routing ("compile error? -> X, trace flow? -> Y")
- **Workflow chains** — multi-step sequences for common tasks (new feature, PR review, bug fix, release)
- **Parallel agent patterns** — which agents to spawn together for comprehensive review

It does NOT contain:
- Skill descriptions (already in system-reminder)
- Language/framework tables (skills auto-trigger from keywords)
- Slash command lists (visible in `/help`)

## Rules (always active)

Two rule files load every session automatically (`alwaysApply: true`):

### `routing-guardrails.md` — Tool Selection Quality
- Single-match tasks skip CLAUDE.md (no overhead for unambiguous work)
- Correct notation: `/cmd` for slash commands, `agent:name` for Agent tool spawns
- Specific skills preferred over general ones
- Effort matches scope (no 4-tool chains for trivial changes)
- Model tier routing (Opus for architecture, Sonnet for implementation)

### `coding-discipline.md` — Behavioral Quality
Inspired by [Andrej Karpathy's CLAUDE.md](https://github.com/forrestchang/andrej-karpathy-skills). Reduces common LLM coding mistakes:
- **Think before coding** — surface assumptions, ask when uncertain
- **Simplicity first** — no speculative features, no unnecessary abstractions
- **Surgical changes** — touch only what the request requires
- **Goal-driven execution** — define success criteria, verify before declaring done

The routing rules tell Claude *which tool* to use. The coding discipline tells Claude *how to behave* while using it. Both are needed.

## Example Output

See `example-output/CLAUDE.md` for a generated routing guide from a setup with ECC, Impeccable, UI-UX-Pro-Max, Document-Skills, C3-Skill, gstack, and GitNexus.

## Token Budget

| Component | Tokens | Loaded |
|-----------|--------|--------|
| Generated CLAUDE.md | ~740 | Every session |
| Routing guardrails rule | ~200 | Every session |
| Coding discipline rule | ~250 | Every session |
| Skill definition | ~1,500 | Only when `/optimize-routing` runs |
| **Total ongoing cost** | **~1,190** | Per session |

Compare to a naive "list everything" CLAUDE.md: ~4,300+ tokens.

## Autoresearch

The project includes an autoresearch harness for iteratively improving routing accuracy:

```bash
bash autoresearch.sh    # Run routing accuracy benchmark
```

This checks 45 assertions (positive and negative routing decisions) against the generated CLAUDE.md and reports accuracy, token count, and line count. See `autoresearch.md` for session config and `autoresearch.jsonl` for run history.

## License

MIT
