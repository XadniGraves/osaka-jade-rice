#!/usr/bin/env bash

set -Eeuo pipefail

UNIT_TARGET="$HOME/.config/systemd/user/osaka-jade-rice-sync.service"

systemctl --user disable --now osaka-jade-rice-sync.service 2>/dev/null || true
if [[ -f "$UNIT_TARGET" ]]; then
  rm -- "$UNIT_TARGET"
fi
systemctl --user daemon-reload
systemctl --user reset-failed osaka-jade-rice-sync.service 2>/dev/null || true

echo "Automatic rice sync disabled."
