---
name: using-superpowers
description: Use when starting any conversation - master orchestrator that triggers appropriate engineering skills based on task complexity while strictly enforcing token efficiency and lean context.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

# Superpowers Master Workflow

Superpowers transforms the coding agent into a disciplined senior engineer while maintaining high speed and **strict token efficiency**.

## 1. Complexity Tiering & Skill Selection (Token-First Approach)

Before jumping into code or ceremony, classify the user request:

### Tier 1: Direct / Atomic (Keep It Fast & Cheap)
- **When to use:** Quick bug fixes, single-component tweaks, styling, git operations, questions, explanations, minor adjustments.
- **Rules:**
  - Execute directly using concise, targeted tools.
  - Do NOT spawn subagents.
  - Do NOT create unnecessary markdown task checklists or multi-turn brainstorming for simple questions.
  - Apply the `token-efficiency` principles: minimal diffs, narrow searches, zero fluff.

### Tier 2: Complex / Multi-File Feature (Use Deep Engineering)
- **When to use:** New product features, architectural redesigns, cross-cutting refactors, complex multi-component bugs.
- **Rules:**
  - **Brainstorming:** If requirements are ambiguous, clarify the scope first in concise chunks (`superpowers:brainstorming`).
  - **Planning:** Formulate a phased, step-by-step plan (`superpowers:writing-plans`).
  - **TDD:** Implement with test-driven discipline (`superpowers:test-driven-development`).
  - **Verification:** Run tests and verify before claiming completion (`superpowers:verification-before-completion`).

### Tier 3: Domain-Specific Telehealth Work
- When working on healthcare, scheduling, patient/doctor portals, or payment flows:
  - Apply `superpowers:telehealth-fullstack` rules (advance notice, timezone handling, zero PHI logging, RBAC).

## 2. Skill Priority

1. **Process & Token Safety:** `token-efficiency` guides tool usage and communication style.
2. **Domain Guidelines:** `telehealth-fullstack` sets healthtech compliance and scheduling constraints.
3. **Engineering Process:** `brainstorming` and `systematic-debugging` set the engineering approach when needed.

## 3. Subagent Guardrail (Crucial for Token Savings)

- Spawning a subagent multiplies token usage 3x to 5x.
- **Rule:** Never launch subagents for linear tasks that the primary agent can finish with a few tool calls. Reserve subagents exclusively for truly independent, parallel tasks.

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Claude Code: `references/claude-code-tools.md`
- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`
- Muse: `references/muse-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc., direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.

