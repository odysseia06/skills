#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer. Modifications to it — or requests for
# modifications — will not be approved.
#
# Links all skills in the repository into the local skill directories used by
# each agent harness:
#   - ~/.claude/skills  — Claude Code
#   - ~/.agents/skills  — Codex and other Agent Skills-compatible harnesses
# Each entry is a symlink into this repo, so a `git pull` is all that's needed
# to keep installed skills up to date.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

link_into() {
  local dest="$1" resolved src name target skill_md

  # If dest is itself a symlink resolving into this repo, linking would write the
  # per-skill symlinks back into the repo's own skills/ tree. Bail out instead.
  if [ -L "$dest" ]; then
    resolved="$(readlink -f "$dest")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $dest is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$dest\") and re-run; the script will recreate it as a real dir." >&2
        return 1
        ;;
    esac
  fi

  mkdir -p "$dest"

  while IFS= read -r -d '' skill_md; do
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$dest/$name"

    # Replace a real dir left by a copy-based install; ln -sfn refreshes a symlink.
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "  linked $name -> $src"
  done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0)
}

for dest in "${DESTS[@]}"; do
  echo "== $dest =="
  link_into "$dest"
done
