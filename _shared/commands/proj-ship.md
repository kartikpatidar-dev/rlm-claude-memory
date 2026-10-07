---
description: After a production push, log changelog entries and refresh rlm-claude-memory docs
argument-hint: "[commit range or PR number]"
---

Record a production release of the current project in its memory.

1. `MEM=../rlm-claude-memory/$(basename "$(git rev-parse --show-toplevel)")`. Read `../rlm-claude-memory/README.md` rules
   and `$MEM/README.md` (it names the production branch).
2. Determine what shipped: use $ARGUMENTS if given, else `git log --oneline <last-verified-hash>..origin/<prod-branch>`
   (fetch first). Get PR numbers/links from merge commit messages or `gh pr list --state merged` if available.
3. Map changed files to modules using `$MEM/module-graph.md` and the module docs' Key files.
4. For each module touched, PREPEND an entry to `$MEM/changelog/<module>.md` (newest first, 3-4 lines):
   ```
   ## YYYY-MM-DD | <module> | PR/commit <ref> | prod
   Why: <reason>
   What: <one or two lines>
   Touches: <other modules/tables>
   ```
5. Update in place, where files/links/tables changed: `$MEM/modules/<name>.md`, `$MEM/module-graph.md`,
   `$MEM/database.md`, `../rlm-claude-memory/system-map.md`.
6. Update `$MEM/status.md` (move shipped items out of in-progress).
7. Bump `Last verified: <date> @ <prod commit hash>` in module-graph.md and in every module doc you re-checked.
8. In `../rlm-claude-memory`: show `git diff --stat`, commit by path with `docs(<project-dir>): ship <ref>`.
   Push only if the user asks. Never write secrets; mark uncertain items UNVERIFIED.
