# Agent Instructions

## graphify

This project has a knowledge graph at `graphify-out/`. Use it as the primary tool for codebase exploration.

- **First tool, every time:** When `graphify-out/graph.json` exists, run `graphify query "<question>"` before any grep/glob/read/bash.
- `graphify path "A" "B"` — shortest path between two concepts.
- `graphify explain "Concept"` — deep-dive on a single node.
- Skip graphify only when: graph doesn't exist, is stale/wrong, the task is not codebase exploration, or the user says so.
- After code changes, `graphify update .` keeps the graph current (AST-only, free).

### rules

Never, and I mean never, remove Users/raphael/JumpGame and JumpGame_Github
