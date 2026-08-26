#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

secret_pattern='-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}|sk-[A-Za-z0-9_-]{24,}'

if rg -I -n --hidden --glob '!scripts/check-secrets.sh' -- "$secret_pattern" \
  config data home profiles state system; then
  echo "Possible secret detected; refusing to commit or publish." >&2
  exit 1
fi

if rg -I -n '/home/[^/[:space:]]+' config home profiles state 2>/dev/null; then
  echo "Machine-specific absolute home path detected; refusing to publish." >&2
  exit 1
fi
