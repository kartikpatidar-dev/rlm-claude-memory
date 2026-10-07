# rlm-claude-memory

Persistent project memory for Claude Code sessions working on the RLM projects.
Each project gets one directory, named exactly like the project's repo folder.
A new session reads the memory here instead of re-scanning the whole codebase.

This repo holds **docs only**. Application code lives in the project repos.

## Layout

```
rlm-claude-memory/                      # cloned as a SIBLING of the project repos
  README.md                             # this file: layout + rules (single source of truth)
  system-map.md                         # how all RLM projects connect (FEs <-> backends)
  _shared/commands/                     # /proj-resume, /proj-handoff, /proj-ship
  <project-dir>/                        # e.g. retailer-verification-portel, rlm-backend-nest
    README.md                           # project entry point: quick facts, prod branch, links
    overview.md                         # what it is, stack, run/test/build commands
    architecture.md                     # layers, data flow, key decisions and WHY
    status.md                           # current state, in-progress work, next steps
    module-graph.md                     # Mermaid graph + Module | Depends on | Used by | Tables
    database.md                         # data layer (DB, tables/collections, ownership)
    modules/<name>.md                   # one file per module, edited in place
    changelog/<name>.md                 # one append-only log per module
    changelog/archive/                  # rolled-up old entries
```

Expected checkout (paths in the commands rely on it):

```
<workspace>/
  rlm-claude-memory/
  retailer-verification-portel/
  rlm-backend-nest/
  rlm-portal/
  rlm-admin-final/
```

The memory directory for a project is `../rlm-claude-memory/<basename of the project repo>/`.

## Projects

| Directory | Repo | Production branch (never push directly) | Last verified |
|---|---|---|---|
| [retailer-verification-portel](retailer-verification-portel/README.md) | Katyayani-Organics/retailer-verification-portel | `aws-v4` | see its module-graph.md |
| [rlm-backend-nest](rlm-backend-nest/README.md) | Katyayani-Organics/rlm-backend-nest | `aws-deployed` | see its module-graph.md |
| rlm-portal | — | not yet torn down | — |
| rlm-admin-final | — | not yet torn down | — |

To add a project: run the same tear-down instruction from inside that project, and save the output under `<project-dir>/` here.

## Rules (apply to every project)

`<mem>` = `rlm-claude-memory/<project-dir>/`.

1. **Session start:** read `<mem>/status.md`. For any task, identify the module(s) involved and read
   `<mem>/modules/<name>.md` and `<mem>/module-graph.md` BEFORE scanning code. Only open source files listed
   there unless the task requires more. For DB or backend work, also read `<mem>/database.md`.
   For work that crosses projects (FE <-> backend), also read `system-map.md`.
2. **Keep docs current (must not be missed):** a code change is NOT complete until the affected memory docs are
   updated: module doc, module-graph.md (nodes, edges, table, Last verified line), database.md (ER diagram and
   ownership table), status.md, and `system-map.md` if a cross-project link changed. Commit the memory update
   in this repo in the same working session as the code change, and reference the project commit/PR in the message.
3. **Triggers that REQUIRE a doc update:** added/moved/removed files in a module; new or changed imports between
   modules; new API routes or a FE starting/stopping to call a backend route; changed DB tables/collections,
   columns, relations, indexes or queries; new env var NAMES; new external service.
4. **Self-check before every project commit**, stated in the commit summary:
   `Docs check: updated <files>` or `Docs check: no doc impact because <reason>`.
5. Module docs, module-graph.md, database.md, status.md and system-map.md are **replaced/edited in place**
   (never appended with history). Only `changelog/*.md` files are append-only.
6. When reading changelogs, read only the latest 5-10 entries unless debugging history.
7. Roll up changelog entries older than ~3 months into a 2-line summary or move them to `changelog/archive/`.
8. **Staleness check at session start:** in the project repo run
   `git diff <last-verified-hash>..HEAD --stat` using the hash in `<mem>/module-graph.md`. If source changed
   since then without a doc update, tell the user and refresh the affected docs first.
9. **Never record secrets**, tokens, passwords, keys or connection strings. Env var NAMES only.
10. **Do not invent facts.** Mark uncertain items `UNVERIFIED` and tell the user.
11. **Git safety:** never push to a production branch (`aws-v4`, `aws-deployed`) or to `main` of any project
    repo directly. In this memory repo, commit by path (never `git add -A`) and never force-push.

## Formats

### Module doc (`modules/<name>.md`), updated in place

```
# <module>
Purpose / Entry points / Key files (dirs + entry files, not every file) / Data (tables) /
Depends on / Used by / External services / Gotchas / Last verified: <date> @ <hash>
```

### Changelog (`changelog/<name>.md`), newest first, 3-4 lines max per entry

```
## YYYY-MM-DD | <module> | PR/commit <ref> | prod
Why: <reason for the change>
What: <what changed, in one or two lines>
Touches: <other modules/tables affected>
```

## Commands

The commands live in `_shared/commands/` and work for any project (they derive `<project-dir>` from the
current repo's folder name). Install them once as user-level commands (see `_shared/commands/README.md`):

- `/proj-resume`: read rules, status, module graph and relevant module docs; summarise where we left off; propose the next step.
- `/proj-handoff`: update status.md and any stale module/graph/database docs.
- `/proj-ship`: after a production push, add changelog entries, update docs, bump Last verified lines.
