#!/usr/bin/env bash
# Claude Code PreToolUse hook (matcher: Bash). Non-blocking.
# When Claude runs `git commit` inside a project repo that has a memory dir in the sibling
# rlm-claude-memory repo, and that memory dir has no uncommitted updates, inject a reminder
# (to Claude) and a one-line notice (to the user) to update the memory docs.
# Never blocks the commit; always exits 0.

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)' || exit 0

# Resolve the repo: honour `git -C <dir>` or a leading `cd <dir> &&`, else the hook cwd.
dir="$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+("([^"]+)"|([^[:space:]]+)).*/\2\3/p' | head -1)"
[ -z "$dir" ] && dir="$(printf '%s' "$cmd" | sed -nE 's/^[[:space:]]*cd[[:space:]]+("([^"]+)"|([^[:space:]&;]+)).*/\2\3/p' | head -1)"
[ -z "$dir" ] && dir="${cwd:-$PWD}"
case "$dir" in /*) ;; *) dir="${cwd:-$PWD}/$dir" ;; esac

repo="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
name="$(basename "$repo")"
memroot="$(dirname "$repo")/rlm-claude-memory"
[ "$name" = "rlm-claude-memory" ] && exit 0
[ -d "$memroot/$name" ] || exit 0

# Memory already being updated in this session? Then stay quiet.
[ -n "$(git -C "$memroot" status --porcelain -- "$name" 2>/dev/null)" ] && exit 0

staged="$(git -C "$repo" diff --cached --name-only 2>/dev/null | head -20 | tr '\n' ' ')"
report="$("$memroot/scripts/check-staleness.sh" "$repo" 2>/dev/null | head -25)"
ctx="RLM memory check: committing in $name but ../rlm-claude-memory/$name/ has no pending updates. Staged: ${staged:-<none>}. Per ../rlm-claude-memory/README.md rules 2-4: update the affected module doc(s), module-graph.md, database.md, status.md (and system-map.md for cross-project links), commit them in rlm-claude-memory, and state 'Docs check: updated <files>' or 'Docs check: no doc impact because <reason>' in the commit message. Staleness report: $report"

jq -n --arg ctx "$ctx" --arg msg "rlm-claude-memory: $name docs not updated in this change (reminder only)" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
exit 0
