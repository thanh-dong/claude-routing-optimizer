---
description: Quality guardrails for plugin and skill routing decisions
alwaysApply: true
---

# Routing Guardrails

**Tradeoff:** These rules bias toward using the right tool. For trivial tasks, use judgment — a single direct action beats a 4-tool chain.

1. **Single-match = skip routing**: If only one skill/agent matches, use it directly. CLAUDE.md exists only for overlap resolution.

2. **Notation discipline**:
   - `/cmd` = slash command (Skill tool)
   - `agent:name` = spawn via Agent tool with `subagent_type`
   - *auto-trigger* = activates from context, never invoked directly
   - Mixing these fails silently.

3. **Verify before recommending**: Confirm a `/command` exists in the skills list before suggesting it. Do not guess names.

4. **Specific over general**: A language-specific reviewer wins over a generic code-review skill. Always prefer the language/framework-specific variant.

5. **Scope-match effort**: 5-line change = one tool. Workflow chains are for substantial work only.

6. **Model routing**: Architecture/planning -> Opus. Implementation/review -> Sonnet. Mechanical tasks -> never Opus.
