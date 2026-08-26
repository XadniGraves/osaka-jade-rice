#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LEVEL="${1:-}"
DESCRIPTION="${2:-Managed rice files updated.}"
VERSION_FILE="$ROOT_DIR/VERSION"

case "$LEVEL" in
  major|minor|patch) ;;
  *) echo "Usage: $0 <major|minor|patch> [description]" >&2; exit 2 ;;
esac

current="$(< "$VERSION_FILE")"
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Invalid VERSION: $current" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$LEVEL" in
  major) ((major += 1)); minor=0; patch=0 ;;
  minor) ((minor += 1)); patch=0 ;;
  patch) ((patch += 1)) ;;
esac

next="$major.$minor.$patch"
temporary="$(mktemp "$ROOT_DIR/.VERSION.XXXXXX")"
printf '%s\n' "$next" > "$temporary"
mv -- "$temporary" "$VERSION_FILE"

cat >> "$ROOT_DIR/CHANGELOG.md" <<EOF

## [$next] - $(date +%F)

### Changed

- $DESCRIPTION
EOF

printf '%s\n' "$next"
