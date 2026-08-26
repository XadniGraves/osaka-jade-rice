#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Repository: $ROOT_DIR"
echo "Version:    $(< "$ROOT_DIR/VERSION")"
echo "Remote:     $(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || echo 'not configured')"
echo
systemctl --user --no-pager --full status osaka-jade-rice-sync.service || true
echo
git -C "$ROOT_DIR" status --short --branch
