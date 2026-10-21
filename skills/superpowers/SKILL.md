---
name: superpowers
description: Invokes the full Superpowers workflow for software engineering, tailored for Telehealth Full Stack (Next.js, TypeScript, React) and Token Efficiency. Triggered on /superpowers or when high-discipline engineering is requested.
---

# Superpowers Workflow (`/superpowers`)

When the user invokes `/superpowers` in the chat, execute this structured software engineering workflow:

## Step 1: Context & Complexity Assessment (Token-First)
- Read the user's intent.
- Apply `superpowers:token-efficiency`:
  - Do NOT spawn subagents if the task can be done sequentially by the primary agent.
  - Do NOT read whole files if line ranges suffice (`StartLine`/`EndLine`).
  - Search surgically using `grep_search` with specific paths.

## Step 2: Domain Context (Telehealth & Healthtech)
- Check `superpowers:telehealth-fullstack`:
  - Verify scheduling rules (minimum advance notice, e.g. 3h).
  - Check timezone consistency (UTC backend, local frontend).
  - Verify compliance (zero PHI in logs, strict RBAC).
  - Next.js architecture (domain logic vs UI, React Query cache invalidation).

## Step 3: Clarification & Specification (Brainstorming)
- If requirements are ambiguous or have multiple technical options:
  - Present brief, structured questions or trade-offs before modifying code.
  - Propose the design in small, digestible blocks.

## Step 4: Implementation Plan & TDD
- For multi-file changes or core domain logic:
  - Formulate a clear, step-by-step implementation plan.
  - Implement with Test-Driven Development (Red-Green-Refactor).

## Step 5: Execution & Verification
- Apply minimal, surgical diffs (`replace_file_content`).
- Run linters and tests to verify correctness before claiming success (`superpowers:verification-before-completion`).
- Summarize changes concisely with direct links to updated symbols and files.
