---
description: Quality guardrails for plugin and skill routing decisions
alwaysApply: true
---

# Routing Quality Guardrails

## Before invoking any skill or spawning any agent

1. **Single-match rule**: If only one installed skill/agent matches the task, use it directly. Do NOT consult CLAUDE.md — it exists only for overlap resolution.

2. **Notation discipline**:
   - Slash commands (`/cmd`): typed in prompt, invoked via Skill tool
   - Agent spawns (`agent:name`): delegated via Agent tool with `subagent_type`
   - Auto-trigger skills: never invoke directly — they activate from context keywords
   - NEVER mix these — spawning an agent as a slash command or invoking a skill as an agent will fail silently

3. **Verify before recommending**: If you're about to suggest a specific `/command` to the user, confirm it exists in the available skills list. Do not guess command names.

4. **Prefer specific over general**: When both a language-specific skill (e.g., `ecc:go-reviewer`) and a general skill (e.g., `ecc:code-review`) match, prefer the specific one.

5. **Scope-match the effort**: Small task = single tool. Don't chain 4 tools for a 5-line change. The CLAUDE.md workflow chains are for substantial work only.

6. **Agent model selection**: Architecture and planning tasks -> Opus agents. Implementation and review -> Sonnet agents. Never use Opus for mechanical tasks.
