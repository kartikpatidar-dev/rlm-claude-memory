---
description: Save session state to rlm-claude-memory (status.md + stale module/graph/database docs)
---

Hand off the current session so the next one can resume from memory.

1. `MEM=../rlm-claude-memory/$(basename "$(git rev-parse --show-toplevel)")`. Read `../rlm-claude-memory/README.md` rules.
2. Collect facts from git in the project repo: current branch, `git status --short`, commits made this session
   (`git log --oneline <last-verified-hash>..HEAD`), and run `../rlm-claude-memory/scripts/check-staleness.sh`
   to see which module docs the changed files map to.
3. Rewrite `$MEM/status.md` IN PLACE (no history): Done / Half-finished (with file pointers) / Next steps /
   Decisions made and why / Open questions. Keep it under ~60 lines.
4. For every module touched this session, update `$MEM/modules/<name>.md` in place if files, routes, imports,
   tables, env var NAMES or external services changed. Update `$MEM/module-graph.md` (nodes, edges, table) and
   `$MEM/database.md` if links or tables changed; update `../rlm-claude-memory/system-map.md` if a cross-project
   link changed. Only bump a `Last verified` line for docs you actually re-checked against code.
5. Never write secrets. Mark anything uncertain UNVERIFIED.
6. In `../rlm-claude-memory`: show `git diff --stat`, then commit by path (never `git add -A`) with message
   `docs(<project-dir>): handoff <short summary>`. Do NOT push unless the user asks.
7. Report what you updated and anything left UNVERIFIED.
