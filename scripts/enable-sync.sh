#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
UNIT_SOURCE="$ROOT_DIR/systemd/osaka-jade-rice-sync.service.in"
UNIT_TARGET="$HOME/.config/systemd/user/osaka-jade-rice-sync.service"

[[ -d "$ROOT_DIR/.git" ]] || { echo "Not a Git repository: $ROOT_DIR" >&2; exit 1; }
git -C "$ROOT_DIR" remote get-url origin >/dev/null 2>&1 || {
  echo "Configure and push an origin remote before enabling automatic sync." >&2
  exit 1
}
command -v inotifywait >/dev/null 2>&1 || {
  echo "inotifywait is missing. Install it with: omarchy pkg add inotify-tools" >&2
  exit 1
}

escaped_root="${ROOT_DIR//\\/\\\\}"
escaped_root="${escaped_root//&/\\&}"
escaped_root="${escaped_root//|/\\|}"
temporary="$(mktemp)"
trap 'rm -f -- "$temporary"' EXIT
sed "s|@REPO_DIR@|$escaped_root|g" "$UNIT_SOURCE" > "$temporary"
install -Dm0644 -- "$temporary" "$UNIT_TARGET"

systemctl --user daemon-reload
systemctl --user enable --now osaka-jade-rice-sync.service

echo "Automatic rice sync enabled."
echo "Service: $UNIT_TARGET"
