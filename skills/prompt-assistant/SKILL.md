---
name: prompt-assistant
description: Use when the user types a long unstructured brainstorming prompt and needs it refined into a structured, token-efficient prompt before Claude acts on it. Triggers on "brainstorm", "I have an idea", "thinking about building", "let's explore", or any 3+ sentence prompt that lacks explicit goal/constraints/success-criteria. Two modes — quick (one-shot rewrite) and deep (ask 2-4 clarifying questions first). Preserves the user's voice; does not invent requirements.
---

# Prompt Assistant

Refines a raw brainstorming prompt into a structured prompt Claude can act on cleanly.

## When to Use

Activate when ALL of these hold:
- The user's message is 3+ sentences of idea/feature/product thinking.
- There is no explicit goal, constraint, or success criterion.
- The user has not already structured the prompt (no headers, no bullet list of requirements).

Do NOT activate for:
- Short direct tasks ("fix this bug", "rename foo to bar").
- Prompts that already have a clear goal + constraints.
- Questions about existing code ("how does X work").

## Modes

**Quick mode** (default): Rewrite the raw prompt into the structured form below in one shot. No questions. Use when the raw prompt has enough signal — a clear-enough idea, hints of context, implicit success criteria.

**Deep mode**: Ask 2-4 targeted clarifying questions first, then rewrite. Use when the raw prompt is missing a critical dimension: no stated goal, no audience, no success criterion, no stack constraints. Ask only what cannot be inferred.

Pick quick unless at least one critical dimension is missing. Announce the mode you chose in one sentence before acting — e.g., "Quick mode — refining now." or "Deep mode — need a few details first."

If the raw input is very thin (minimal signal, one vague sentence, no clear feature), force deep mode. Do not try to refine almost-no-signal input in quick mode.

If the user references files with `@path/to/file` syntax, capture those references verbatim in the Context section.

## Repo Awareness

The user typically opens with "work on this repo and brainstorm for X feature" (or "brainstorm for X"). When this phrasing appears, the feature becomes the Goal, and "this repo" means: inspect the repo state (layout, stack, files touching the feature) before refining.

- Git repo with existing code → refined prompt includes "Existing codebase: <stack>" and references specific files.
- Greenfield / empty → refined prompt includes "Greenfield — no existing code" and captures any stated stack preferences.

Never invent a stack the user did not mention.

## Refined Prompt Template

Output exactly this structure. Omit a section only if the user's input has zero signal for it — never fabricate content.

```
## Goal
<one sentence: the outcome the user wants from this brainstorm>

## Context
<existing code / greenfield, stack, audience, any background the user provided>

## What's Known
<facts, decisions, constraints the user stated>

## What's Open
<questions, undecided choices, things to explore>

## Success Criteria
<how the user will know the brainstorm produced something useful>

## Constraints
<must/must-not, hard limits>
```

## Rules

1. **Preserve the user's voice.** If they wrote "I wanna build a tiny CLI that…", keep "tiny" and "CLI". Do not corporate-ify.
2. **Do not expand.** Refined prompt should be equal or shorter in token count than the raw input. Keep sections brief — 1-2 sentences each. No filler, no padding. Structure is the value, not verbosity.
3. **Do not invent requirements.** If the user did not say "must be in Rust", do not write that. Leave What's Open empty rather than fabricating.
4. **One re-ask max.** If in deep mode, ask all clarifying questions in a single batched turn. Never ping-pong.
5. **End with a handoff.** After the refined prompt block, add one line: "Ready to explore — shall I proceed, or do you want to edit this first?"

## Examples

Raw input:
> I've been thinking about this thing where like you could have a small tool that helps you write better git commit messages, maybe using ai, and it would look at the diff and suggest something, i'm not sure if it should be a CLI or a hook or what

Refined (quick mode):

```
## Goal
Build a small tool that suggests better git commit messages by analyzing the diff.

## Context
Greenfield — no existing code. AI-assisted.

## What's Known
- Input: git diff
- Output: suggested commit message

## What's Open
- Delivery: CLI vs git hook vs editor plugin
- Which AI (local model vs API)
- Scope: single-line suggestions vs full Conventional Commits format

## Success Criteria
Tool produces a commit message good enough to use as-is ≥70% of the time.

## Constraints
Keep it small.
```

Ready to explore — shall I proceed, or do you want to edit this first?

### Refined (deep mode)

Raw input:
> work on this repo and brainstorm for a notifications feature

Mode: Deep mode — need a few details first.

Before refining, answer:
1. Who receives the notifications — end users, developers, or system operators?
2. Channels — in-app, email, push, all of the above?
3. Triggered by what events?
4. Success criterion — what does "working notifications" mean to you?

Once you answer, the refined prompt follows the same template as the quick-mode example above.
