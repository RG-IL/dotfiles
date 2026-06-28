# Agent Instructions

## ⚠️ CRITICAL: graphify is the ONLY way to explore code. No grep/glob/read/find/ls/bash.

**The user has explicitly demanded that you use graphify for ALL codebase exploration, file searching, and information gathering.** If you use `grep`, `glob`, `read`, `bash find`, `bash ls`, or any other tool for codebase discovery without trying graphify first, you are violating a hard instruction.

**graphify replaces grep/glob/read/find/ls/bash for all codebase searches.** These tools are LAST RESORT only — do not reach for them unless graphify-out/ does not exist or graphify returns stale/clearly-wrong results.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships. The graph is always your first and primary tool.

Rules:
- **Always start with** `graphify query "<question>"` when graphify-out/graph.json exists. Formulate your question as a natural-language query about what you need to find.
- Use `graphify path "<A>" "<B>"` for relationships between two concepts/files.
- Use `graphify explain "<concept>"` for focused deep-dives on a single concept.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing — it gives a structured overview.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are **not** a reason to skip graphify.
- Only skip graphify if: the task is about stale or incorrect graph output, the user explicitly tells you to skip it, or graphify-out/ does not exist.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing anything else.

