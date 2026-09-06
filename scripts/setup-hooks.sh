#!/bin/sh
#
# Install this repository's git hooks.
#
#   ./scripts/setup-hooks.sh
#
# WHY core.hooksPath, AND NOT A COPY INTO .git/hooks/
#
# `.git/` is not part of the repository, so a hook copied into `.git/hooks/`
# exists only on the machine that copied it. A fresh clone has no protection, the
# file can be deleted without `git status` noticing, and nothing in code review
# shows what the hook actually does. Pointing git at the committed `.githooks/`
# directory instead makes the hooks versioned, reviewable files that every clone
# installs identically — and changing them is an ordinary commit.
#
# This repository is Markdown and nothing else, and it is still worth installing:
# without it, the `Co-authored-by: Cursor` trailer that this environment injects
# lands in commits here and nowhere else, because every other repository has the
# same hook. That is exactly how one got into `831a567` before this file existed.
#
# Idempotent: re-running changes nothing the second time. `.git/hooks/` is never
# touched, so any hook already there is left alone.

set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "error: not inside a git repository." >&2
  exit 1
}
cd "$repo_root"

hooks_dir=.githooks

if [ ! -d "$hooks_dir" ]; then
  echo "error: $hooks_dir/ is missing from this checkout." >&2
  exit 1
fi

# `--local` on purpose: the setting belongs to this clone, not to the user's
# global git config, so it cannot leak into unrelated repositories.
previous=$(git config --local --get core.hooksPath || true)

if [ "$previous" = "$hooks_dir" ]; then
  echo "core.hooksPath is already $hooks_dir — nothing to change."
else
  git config --local core.hooksPath "$hooks_dir"
  if [ -n "$previous" ]; then
    echo "core.hooksPath: $previous -> $hooks_dir"
  else
    echo "core.hooksPath: (unset) -> $hooks_dir"
  fi
fi

# Git only runs a hook file that is executable. The bit survives a clone, but
# restoring it here is free and repairs a checkout made on a filesystem that
# dropped it.
if [ -f "$hooks_dir/commit-msg" ]; then
  chmod +x "$hooks_dir/commit-msg"
  echo "enabled: $hooks_dir/commit-msg"
else
  echo "warning: $hooks_dir/commit-msg is missing." >&2
fi

echo
echo "Git now runs hooks from $hooks_dir/. Verify with: git config --local core.hooksPath"
echo "To opt out again: git config --local --unset core.hooksPath"
