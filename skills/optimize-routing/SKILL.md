---
name: optimize-routing
description: Scan all installed plugins, skills, agents, and commands, detect overlaps, and regenerate ~/.claude/CLAUDE.md as an optimal routing guide. Use when the user says "optimize routing", "update CLAUDE.md", "regenerate routing guide", "new plugin installed", or after adding/removing plugins or skills. Also use after /optimize-routing command.
---

# Plugin Routing Optimizer

You are a meta-skill that introspects the entire Claude Code installation and generates an optimal `~/.claude/CLAUDE.md` routing guide.

## Why This Exists

When multiple plugins provide overlapping capabilities (e.g., 3 plugins can do code review), Claude needs disambiguation rules. The skill system auto-triggers from description keywords, but it cannot resolve conflicts between plugins. The CLAUDE.md fills that gap — it contains ONLY overlap resolution rules and workflow chains, nothing the skill system already handles.

## Execution Steps

### Phase 1: Inventory

Scan and catalog all installed plugins, skills, agents, and commands.

1. **Read installed plugins**:
   ```bash
   cat ~/.claude/plugins/installed_plugins.json
   ```

2. **Read settings to find enabled/disabled plugins**:
   ```bash
   cat ~/.claude/settings.json | grep -A 20 enabledPlugins
   ```

3. **For each enabled plugin, read its manifest**:
   ```bash
   # Pattern: ~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/.claude-plugin/plugin.json
   find ~/.claude/plugins/cache -name "plugin.json" -path "*/.claude-plugin/*" 2>/dev/null
   ```

4. **Catalog local skills**:
   ```bash
   ls ~/.claude/skills/
   ```

5. **Catalog local commands**:
   ```bash
   ls ~/.claude/commands/
   ```

6. **For each plugin, list its agents**:
   ```bash
   # Read agent directories from plugin manifests
   ```

7. **For each plugin, list its skills with descriptions**:
   Read the `description` field from each SKILL.md frontmatter (first 5 lines).

### Phase 2: Overlap Detection

Group capabilities by **task domain** and identify where multiple plugins compete:

**Task domains to check:**
- Code review (ECC reviewers vs gstack /review vs GitNexus /gitnexus-pr-review vs any other)
- Testing (ECC /tdd vs gstack /qa vs any TDD-focused plugin)
- Debugging (ECC build resolvers vs gstack /investigate vs GitNexus /gitnexus-debugging)
- Frontend design (Impeccable vs UI-UX-Pro-Max vs Document-Skills vs gstack design-* vs ECC frontend-*)
- Architecture (C3-Skill vs ECC architect vs any planning skills)
- Security (ECC security-* vs gstack /cso vs any security plugin)
- Deployment/shipping (gstack /ship vs ECC deployment-*)
- Documentation (Document-Skills vs C3 vs gstack /document-release vs ECC docs)
- Refactoring (GitNexus vs ECC refactor-cleaner)
- Performance (ECC performance-optimizer vs gstack /benchmark)
- Planning (ECC /plan vs gstack /autoplan vs any plan-related skills)
- Research (ECC deep-research vs ECC exa-search vs any research skills)

**Detection rules:**
- Two or more plugins provide skills/agents for the same task domain = OVERLAP
- A single plugin owns a domain exclusively = NO OVERLAP (skip in CLAUDE.md)
- A skill that auto-triggers reliably from keywords = NO NEED to mention in CLAUDE.md

### Phase 3: Generate CLAUDE.md

Write `~/.claude/CLAUDE.md` with this exact structure:

```markdown
# Plugin Routing Guide

This guide ONLY applies when a task matches multiple plugins. For tasks that clearly
match a single skill description, use that skill directly without consulting this guide.

**Notation**: `/cmd` = slash command. `agent:name` = spawn via Agent tool. *italic* = auto-trigger skill (activates from context, not invoked directly).

## Overlap Resolution

{For each detected overlap domain, write a conditional routing block:}

**{Domain name}**:
- {condition}? -> {best tool} ({why in 3-5 words})
- {condition}? -> {alternative tool}
- {default/chain for important cases}

## Workflows

{Generate 4-6 workflow chains for the most common multi-step tasks:}

**{Workflow name}**: step1 -> step2 -> step3

## Parallel Agents

{List agent combinations that should be spawned in parallel for comprehensive work}
```

**CLAUDE.md rules:**
- Target: under 80 lines, under 1000 tokens
- NEVER list skills that have no overlap (the skill system handles them)
- NEVER duplicate skill descriptions (already in system-reminder)
- NEVER include language/framework tables (ECC skill descriptions auto-trigger)
- Use conditional routing ("if X then Y") not declarative lists ("Y is for X")
- Use correct notation: `/cmd` for slash commands, `agent:name` for Agent tool spawns, *italic* for auto-trigger skills
- Verify command names exist before including them (check commands/ directories)
- Mark disabled plugins with a note if they have significant overlaps

### Phase 4: Verify

After writing CLAUDE.md:

1. **Check all referenced commands exist** — grep each `/command` name against installed skill/command directories
2. **Check all referenced agents exist** — grep each `agent:name` against plugin agent directories
3. **Estimate token count** — `wc -c ~/.claude/CLAUDE.md` and divide by 4. Target: <1000 tokens.
4. **Check line count** — `wc -l ~/.claude/CLAUDE.md`. Target: <80 lines.
5. If over budget, cut the least-impactful overlap section (fewest plugins competing)

### Phase 5: Report

Output a summary to the user:

```
Routing Guide Updated: ~/.claude/CLAUDE.md
- Plugins scanned: N enabled, M disabled
- Skills cataloged: N total across M plugins
- Overlaps detected: N domains with conflicts
- Overlaps resolved: N routing rules written
- Token cost: ~N tokens (target: <1000)
- Lines: N (target: <80)

Changes from previous version:
- Added: {new overlap sections}
- Removed: {sections no longer needed}
- Updated: {sections with changed routing}
```

## Quality Rules

1. **No redundancy with skill system** — if a skill's description already uniquely identifies it, don't mention it in CLAUDE.md
2. **Conditional over declarative** — "compile error? -> X" not "X handles compile errors"
3. **Workflows must chain to completion** — every workflow should end at a natural stopping point (PR created, deployed, bug fixed)
4. **Verify before writing** — check that every command/agent name referenced actually exists in the installation
5. **Forward-compatible** — note disabled plugins that have overlaps, so re-enabling them doesn't break routing
