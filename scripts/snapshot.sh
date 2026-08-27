#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_SYSTEM=0

if [[ "${1:-}" == "--system" ]]; then
  INCLUDE_SYSTEM=1
  shift
fi
[[ $# -eq 0 ]] || { echo "Usage: $0 [--system]" >&2; exit 2; }

copy_file() {
  local source="$1"
  local target="$2"

  [[ -f "$source" ]] || { echo "Managed source file is missing: $source" >&2; exit 1; }
  mkdir -p -- "$(dirname -- "$target")"
  rsync -a --no-owner --no-group -- "$source" "$target"
}

copy_dir() {
  local source="$1"
  local target="$2"

  [[ -d "$source" ]] || { echo "Managed source directory is missing: $source" >&2; exit 1; }
  mkdir -p -- "$target"
  rsync -a --no-owner --no-group --delete \
    --exclude='*.bak' --exclude='*.bak.*' --exclude='*.OMARCHY.original' \
    --exclude='backups/' -- "$source/" "$target/"
}

snapshot_config() {
  local relative

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    copy_file "$HOME/.config/$relative" "$ROOT_DIR/config/$relative"
  done < "$ROOT_DIR/manifest/config-files.txt"

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    copy_dir "$HOME/.config/$relative" "$ROOT_DIR/config/$relative"
  done < "$ROOT_DIR/manifest/config-dirs.txt"

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    copy_file "$HOME/$relative" "$ROOT_DIR/home/$relative"
  done < "$ROOT_DIR/manifest/home-files.txt"
}

snapshot_fastfetch() {
  copy_dir "$HOME/.local/share/undead-sprites" "$ROOT_DIR/data/undead-sprites"
  copy_dir "$HOME/.local/share/beast-girls" "$ROOT_DIR/data/beast-girls"
}

snapshot_profile() {
  local relative

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    copy_file "$HOME/.config/$relative" "$ROOT_DIR/profiles/primary/$relative"
  done < "$ROOT_DIR/manifest/profile-files.txt"
}

snapshot_system() {
  local relative

  ((INCLUDE_SYSTEM)) || return 0
  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    copy_file "/$relative" "$ROOT_DIR/system/$relative"
  done < "$ROOT_DIR/manifest/system-files.txt"
}

snapshot_config
snapshot_fastfetch
snapshot_profile
snapshot_system
