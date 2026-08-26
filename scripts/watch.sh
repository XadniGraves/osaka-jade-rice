#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v inotifywait >/dev/null 2>&1 || {
  echo "inotifywait is required. Install the inotify-tools package." >&2
  exit 1
}

watch_paths=(
  "$HOME/.config/alacritty"
  "$HOME/.config/fastfetch/config.jsonc"
  "$HOME/.config/foot"
  "$HOME/.config/ghostty"
  "$HOME/.config/hypr"
  "$HOME/.config/kitty"
  "$HOME/.config/omarchy/backgrounds/osaka-jade"
  "$HOME/.config/omarchy/branding/screensaver.txt"
  "$HOME/.config/omarchy/hooks/post-boot.d"
  "$HOME/.config/omarchy/plugins/xadni.lock"
  "$HOME/.config/omarchy/plugins/xadni.welcome"
  "$HOME/.config/omarchy/shell.json"
  "$HOME/.config/omarchy/themes/osaka-jade"
  "$HOME/.config/omarchy/welcome.json"
  "$HOME/.local/bin/undead-fetch"
  "$HOME/.local/bin/welcome"
  "$HOME/.local/share/undead-sprites"
  "$HOME/.bashrc"
)

for path in "${watch_paths[@]}"; do
  [[ -e "$path" ]] || { echo "Managed watch path is missing: $path" >&2; exit 1; }
done

run_sync() {
  if ! "$ROOT_DIR/scripts/sync.sh"; then
    echo "Rice sync failed; the watcher will retry after the next change or periodic check." >&2
  fi
}

wait_for_event() {
  local timeout_seconds="$1"
  inotifywait -qq -r -t "$timeout_seconds" \
    -e close_write,create,delete,move,attrib -- "${watch_paths[@]}"
}

run_sync

while true; do
  if wait_for_event 900; then
    while wait_for_event 30; do
      :
    done
    run_sync
  else
    run_sync
  fi
done
