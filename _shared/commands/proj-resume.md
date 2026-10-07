---
description: Resume work on this project from rlm-claude-memory (status, module graph, module docs)
argument-hint: "[module or task hint]"
---

Resume work on the current project using its persistent memory.

1. Find the memory directory: `MEM=../rlm-claude-memory/$(basename "$(git rev-parse --show-toplevel)")`.
   If it does not exist, say so and stop (the project has not been torn down yet).
2. Pull the memory repo read-only state: `git -C ../rlm-claude-memory pull --ff-only` (skip if offline; say so).
3. Read `../rlm-claude-memory/README.md` (rules), `$MEM/README.md`, `$MEM/status.md`, `$MEM/module-graph.md`.
4. Staleness check: take the hash from the `Last verified:` line in `$MEM/module-graph.md` and run
   `git diff <hash>..HEAD --stat` in the project repo. List source areas changed since then and which module docs
   they map to. If anything is stale, say so before anything else.
5. If the user gave a hint ($ARGUMENTS) or status.md names in-progress work, read the matching
   `$MEM/modules/<name>.md` (and `$MEM/database.md` for DB/backend work, `../rlm-claude-memory/system-map.md` for
   cross-project work). Read only the latest 5-10 entries of any changelog you open.
6. Report in under 20 lines: current branch, where we left off, stale docs (if any), and ONE proposed next step.
   Do not start coding until the user confirms.
