---
name: token-efficiency
description: Critical guidelines to minimize token consumption, keep context lean, avoid redundant subagents, and optimize tool usage for cost-effective development.
---

# Token Efficiency & Lean Context Workflow

This skill enforces strict token-saving practices to prevent token bloat, reduce API costs, and keep model responses fast and focused.

## 1. Complexity Tiering (Stop Over-Engineering Simple Tasks)

Always categorize incoming requests into the appropriate complexity tier:

- **Tier 1: Atomic / Direct (Low Tokens)**
  - *Examples:* Bugfix in 1-2 files, git commands, styling adjustments, answering questions, writing a small utility function, updating types.
  - *Action:* **Direct execution.** Do NOT invoke subagents, do NOT create elaborate multi-stage task artifacts, do NOT force brainstorming cycles. Inspect the targeted code, apply the change cleanly, verify, and respond.

- **Tier 2: Feature / Architectural (Moderate to High Tokens)**
  - *Examples:* Multi-component architectural refactor, brand new feature domain, breaking database migration, external gateway integration.
  - *Action:* Use structured planning (`writing-plans`), brief clarifying questions, and progressive execution.

## 2. Tool & Search Optimization

1. **Surgical File Reads:**
   - Never view an entire 1000+ line file when only a specific function or line range is needed. Use `StartLine` and `EndLine`.
   - Never re-read files that are already loaded in the active context window.

2. **Precise Grep Searches:**
   - Always narrow `grep_search` using `Includes` (e.g. `*.ts`, `*.tsx`) and specific `SearchPath` subdirectories instead of broad searches across the whole workspace.
   - Set `MatchPerLine: false` when you only need to locate which files contain a symbol.

3. **Minimal Targeted Diffs:**
   - Never replace whole files or large surrounding blocks when modifying code. Use `replace_file_content` with concise, unique target chunks.

## 3. Subagent Conservation

- **Subagents duplicate system prompt context, tool definitions, and conversation overhead (costing 3x-5x more tokens).**
- **Strict Rule:** NEVER spawn subagents for tasks that can be performed sequentially by the primary agent in a few tool calls.
- Only consider subagents when there are 2+ truly independent, long-running parallel tasks with disjoint file sets.

## 4. Context Compaction & Response Hygiene

- **Cut the Fluff:** Avoid verbose pleasantries, repeating the user's prompt back to them, or writing paragraphs explaining unchanged code.
- **Diff & Rationale:** Provide concise explanations of what changed and why, linking directly to affected symbols or files.
- **Surviving Long Sessions:** Keep long-running state in persistent documents or commit checkpoints instead of relying on early chat turns that will get compacted.
