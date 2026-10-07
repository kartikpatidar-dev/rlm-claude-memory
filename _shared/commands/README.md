# Shared commands

`/proj-resume`, `/proj-handoff` and `/proj-ship` work for every project. Each one derives the memory directory from
the current repo's folder name (`../rlm-claude-memory/<basename>/`), so one copy serves all projects and the
project repos stay untouched.

## Install (once per machine)

User-level commands live in `~/.claude/commands/`. Symlink them so `git pull` here keeps them current:

```bash
mkdir -p ~/.claude/commands
for c in proj-resume proj-handoff proj-ship; do
  ln -s "$(pwd)/_shared/commands/$c.md" ~/.claude/commands/$c.md   # run from the rlm-claude-memory root
done
```

If a command with the same name already exists in `~/.claude/commands/`, do not overwrite it. Rename the link instead
(for example `rlm-resume.md`).

## Requirement

The project repo and `rlm-claude-memory` must be siblings in the same parent folder.
