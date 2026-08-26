#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_SYSTEM=0

if [[ "${1:-}" == "--system" ]]; then
  INCLUDE_SYSTEM=1
  shift
fi
[[ $# -eq 0 ]] || { echo "Usage: $0 [--system]" >&2; exit 2; }

cd "$ROOT_DIR"
[[ -d .git ]] || { echo "Automatic sync requires a Git repository: $ROOT_DIR" >&2; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "flock is required for automatic sync" >&2; exit 1; }

exec 9>"$ROOT_DIR/.git/osaka-jade-rice-sync.lock"
if ! flock -n 9; then
  echo "Another rice sync is already running; skipping."
  exit 0
fi

snapshot_args=()
managed_paths=(config data home profiles state)
if ((INCLUDE_SYSTEM)); then
  snapshot_args+=(--system)
  managed_paths+=(system)
fi

"$ROOT_DIR/scripts/snapshot.sh" "${snapshot_args[@]}"
"$ROOT_DIR/scripts/check-secrets.sh"

managed_status="$(git status --porcelain -- "${managed_paths[@]}")"
new_version=""

if [[ -n "$managed_status" ]]; then
  mapfile -t all_changed_files < <(git status --porcelain -- "${managed_paths[@]}" | sed -E 's/^.. //')
  changed_files=("${all_changed_files[@]:0:8}")
  summary="Synced ${#all_changed_files[@]} managed path(s)"
  if ((${#changed_files[@]})); then
    joined="$(IFS=', '; echo "${changed_files[*]}")"
    summary+=" ($joined)"
  fi

  new_version="$("$ROOT_DIR/scripts/bump-version.sh" patch "$summary")"
  git add -- "${managed_paths[@]}" VERSION CHANGELOG.md
  git commit -m "chore(sync): update rice snapshot (v$new_version)"
  git tag -a "v$new_version" -m "Osaka Jade Rice v$new_version"
  echo "Created rice snapshot v$new_version."
else
  echo "Managed rice files are already current."
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "No origin remote is configured; the local snapshot was not pushed." >&2
  exit 0
fi

branch="$(git branch --show-current)"
[[ -n "$branch" ]] || { echo "Cannot push from a detached HEAD." >&2; exit 1; }

export GIT_TERMINAL_PROMPT=0

if [[ -z "$(git status --porcelain --untracked-files=no)" ]]; then
  git fetch origin "$branch"
  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git rebase "origin/$branch"
  fi
else
  echo "Non-rice repository edits are present; skipping rebase and attempting a direct push." >&2
fi

git push origin "HEAD:$branch" --follow-tags
echo "GitHub is up to date${new_version:+ at v$new_version}."
