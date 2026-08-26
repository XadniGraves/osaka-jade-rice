#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "Validation failed: $*" >&2
  exit 1
}

while IFS= read -r script; do
  bash -n "$script"
done < <(find . -type f -name '*.sh' -print | sort)
bash -n install.sh

version="$(< VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION is not semantic: $version"

jq -e . config/omarchy/shell.json >/dev/null
jq -e . config/omarchy/plugins/xadni.lock/manifest.json >/dev/null

selected_sprite="$(< state/fastfetch-current-sprite)"
[[ "$selected_sprite" == "$(basename -- "$selected_sprite")" ]] || fail "invalid selected sprite path"
[[ -f "data/undead-sprites/$selected_sprite" ]] || fail "selected sprite is missing"

while IFS= read -r relative || [[ -n "$relative" ]]; do
  [[ -n "$relative" && "$relative" != \#* ]] || continue
  [[ -f "config/$relative" ]] || fail "missing config file: $relative"
done < manifest/config-files.txt

while IFS= read -r relative || [[ -n "$relative" ]]; do
  [[ -n "$relative" && "$relative" != \#* ]] || continue
  [[ -d "config/$relative" ]] || fail "missing config directory: $relative"
done < manifest/config-dirs.txt

while IFS= read -r relative || [[ -n "$relative" ]]; do
  [[ -n "$relative" && "$relative" != \#* ]] || continue
  [[ -f "home/$relative" ]] || fail "missing home file: $relative"
done < manifest/home-files.txt

while IFS= read -r relative || [[ -n "$relative" ]]; do
  [[ -n "$relative" && "$relative" != \#* ]] || continue
  [[ -f "profiles/primary/$relative" ]] || fail "missing profile file: $relative"
done < manifest/profile-files.txt

while IFS= read -r relative || [[ -n "$relative" ]]; do
  [[ -n "$relative" && "$relative" != \#* ]] || continue
  [[ -f "system/$relative" ]] || fail "missing system file: $relative"
done < manifest/system-files.txt

oversized="$(find . -path ./.git -prune -o -type f -size +95M -print -quit)"
[[ -z "$oversized" ]] || fail "file is too large for GitHub: $oversized"

./scripts/check-secrets.sh

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

echo "Validation passed for Osaka Jade Rice v$version."
