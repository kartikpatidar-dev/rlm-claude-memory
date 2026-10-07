#!/usr/bin/env bash
# Report which memory docs may be stale for a project.
#
# Usage:
#   scripts/check-staleness.sh [project-repo-path]   # default: current git repo
#   scripts/check-staleness.sh --all                 # every project dir in this memory repo
#
# Reads "Last verified: ... @ <hash>" from <mem>/module-graph.md, lists files changed in the
# project repo since that commit (committed + uncommitted), and maps each file to the module
# docs that mention its path. Read-only; always exits 0.

set -uo pipefail
MEM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$(dirname "$MEM_ROOT")"

check_one() {
  local repo name mem hash changed head pending
  repo="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo: $1"; return; }
  name="$(basename "$repo")"
  mem="$MEM_ROOT/$name"
  [ -d "$mem" ] || { echo "[$name] no memory directory yet (run the tear-down)"; return; }
  hash="$(grep -m1 -oE 'Last verified:.*@ *[0-9a-f]{7,40}' "$mem/module-graph.md" 2>/dev/null | grep -oE '[0-9a-f]{7,40}$')"
  [ -n "$hash" ] || { echo "[$name] no 'Last verified ... @ <hash>' line in module-graph.md"; return; }
  git -C "$repo" cat-file -e "$hash^{commit}" 2>/dev/null || { echo "[$name] last-verified commit $hash not found locally (git fetch?)"; return; }

  changed="$( { git -C "$repo" diff --name-only "$hash"..HEAD; git -C "$repo" diff --name-only HEAD; git -C "$repo" ls-files --others --exclude-standard; } \
              | grep -vE '^(node_modules|dist|build|coverage)/|lock\.json$|\.lockb?$|^pnpm-lock\.yaml$' | sort -u)"
  head="$(git -C "$repo" rev-parse --short HEAD)"
  if [ -z "$changed" ]; then echo "[$name] up to date: no changes since $hash (HEAD $head)"; return; fi

  echo "[$name] $(printf '%s\n' "$changed" | wc -l) file(s) changed since last-verified $hash (HEAD $head)"
  declare -A hits=()
  local unmapped=() f p found m
  while IFS= read -r f; do
    p="$f"; found=""
    # Root-level files (CLAUDE.md, package.json, ...) are project-wide, not module-owned.
    case "$p" in */*) ;; *) unmapped+=("$f"); continue ;; esac
    while [ -n "$p" ] && [ "$p" != "." ]; do
      found="$(grep -rlF -- "$p" "$mem/modules" 2>/dev/null | while IFS= read -r d; do basename "$d" .md; done | sort -u | tr '\n' ' ')"
      [ -n "$found" ] && break
      [ "$(dirname "$p")" = "$p" ] && break
      p="$(dirname "$p")"
    done
    if [ -n "$found" ]; then for m in $found; do hits[$m]+="$f"$'\n'; done; else unmapped+=("$f"); fi
  done <<< "$changed"

  for m in $(printf '%s\n' "${!hits[@]}" | sort); do
    echo "  module $m ($(printf '%s' "${hits[$m]}" | grep -c .) file(s)) -> $name/modules/$m.md"
    printf '%s' "${hits[$m]}" | head -5 | sed 's/^/      /'
  done
  if [ ${#unmapped[@]} -gt 0 ]; then
    echo "  not mapped to any module doc (${#unmapped[@]}):"; printf '      %s\n' "${unmapped[@]:0:8}"
  fi
  pending="$(git -C "$MEM_ROOT" status --porcelain -- "$name" | wc -l)"
  echo "  memory dir $name/: $pending uncommitted change(s)"
}

if [ "${1:-}" = "--all" ]; then
  for d in "$MEM_ROOT"/*/; do
    n="$(basename "$d")"
    case "$n" in _shared|scripts) continue ;; esac
    if [ -d "$WORKSPACE/$n/.git" ]; then check_one "$WORKSPACE/$n"; else echo "[$n] project repo not found at $WORKSPACE/$n"; fi
  done
else
  check_one "${1:-$PWD}"
fi
exit 0
