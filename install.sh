#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/osaka-jade-rice/backups/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
INSTALL_SYSTEM=0
APPLY_RICE=1
PROFILE=""
BACKUP_CREATED=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --profile NAME       Install a machine profile, for example "primary"
  --system-branding    Install SDDM/Plymouth overlays and rebuild initramfs
  --skip-apply         Copy files without applying/restarting the live rice
  --dry-run            Print intended changes without writing anything
  -h, --help           Show this help
EOF
}

while (($#)); do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { echo "--profile requires a name" >&2; exit 2; }
      PROFILE="$2"
      shift 2
      ;;
    --system-branding)
      INSTALL_SYSTEM=1
      shift
      ;;
    --skip-apply)
      APPLY_RICE=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for command in omarchy jq rsync; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

if [[ -n "$PROFILE" ]]; then
  [[ "$PROFILE" != */* && "$PROFILE" != .* ]] || {
    echo "Invalid profile name: $PROFILE" >&2
    exit 2
  }
  [[ -d "$ROOT_DIR/profiles/$PROFILE" ]] || {
    echo "Profile does not exist: $PROFILE" >&2
    exit 1
  }
fi

backup_user_target() {
  local target="$1"
  local relative destination

  [[ -e "$target" || -L "$target" ]] || return 0
  relative="${target#"$HOME"/}"
  destination="$BACKUP_ROOT/home/$relative"

  if ((DRY_RUN)); then
    printf 'Would back up %s -> %s\n' "$target" "$destination"
    return
  fi

  mkdir -p -- "$(dirname -- "$destination")"
  cp -a -- "$target" "$destination"
  BACKUP_CREATED=1
}

install_user_file() {
  local source="$1"
  local target="$2"

  [[ -f "$source" ]] || { echo "Missing repository file: $source" >&2; exit 1; }
  backup_user_target "$target"

  if ((DRY_RUN)); then
    printf 'Would install %s -> %s\n' "$source" "$target"
    return
  fi

  mkdir -p -- "$(dirname -- "$target")"
  rsync -a -- "$source" "$target"
}

install_user_dir() {
  local source="$1"
  local target="$2"

  [[ -d "$source" ]] || { echo "Missing repository directory: $source" >&2; exit 1; }
  backup_user_target "$target"

  if ((DRY_RUN)); then
    printf 'Would synchronize %s/ -> %s/\n' "$source" "$target"
    return
  fi

  mkdir -p -- "$target"
  rsync -a --delete -- "$source/" "$target/"
}

install_config_payload() {
  local relative

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    install_user_file "$ROOT_DIR/config/$relative" "$HOME/.config/$relative"
  done < "$ROOT_DIR/manifest/config-files.txt"

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    install_user_dir "$ROOT_DIR/config/$relative" "$HOME/.config/$relative"
  done < "$ROOT_DIR/manifest/config-dirs.txt"

  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    install_user_file "$ROOT_DIR/home/$relative" "$HOME/$relative"
  done < "$ROOT_DIR/manifest/home-files.txt"
}

install_fastfetch_assets() {
  local selected_sprite target_link

  install_user_dir "$ROOT_DIR/data/undead-sprites" "$HOME/.local/share/undead-sprites"
  install_user_dir "$ROOT_DIR/data/beast-girls" "$HOME/.local/share/beast-girls"
  selected_sprite="$(< "$ROOT_DIR/state/fastfetch-current-sprite")"
  [[ "$selected_sprite" == "$(basename -- "$selected_sprite")" ]] || {
    echo "Invalid Fastfetch sprite state: $selected_sprite" >&2
    exit 1
  }
  [[ -f "$ROOT_DIR/data/undead-sprites/$selected_sprite" ]] || {
    echo "Selected Fastfetch sprite is missing: $selected_sprite" >&2
    exit 1
  }

  target_link="$HOME/.config/fastfetch/undead-current.png"
  backup_user_target "$target_link"
  if ((DRY_RUN)); then
    printf 'Would link %s -> %s\n' "$target_link" "$HOME/.local/share/undead-sprites/$selected_sprite"
  else
    mkdir -p -- "$(dirname -- "$target_link")"
    ln -sfn -- "$HOME/.local/share/undead-sprites/$selected_sprite" "$target_link"
  fi
}

install_profile() {
  local relative

  [[ -n "$PROFILE" ]] || return 0
  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    install_user_file "$ROOT_DIR/profiles/$PROFILE/$relative" "$HOME/.config/$relative"
  done < "$ROOT_DIR/manifest/profile-files.txt"
}

install_system_branding() {
  local relative source target backup

  ((INSTALL_SYSTEM)) || return 0
  while IFS= read -r relative || [[ -n "$relative" ]]; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    source="$ROOT_DIR/system/$relative"
    target="/$relative"
    backup="$BACKUP_ROOT/system/$relative"
    [[ -f "$source" ]] || { echo "Missing repository file: $source" >&2; exit 1; }

    if [[ -f "$target" ]]; then
      if ((DRY_RUN)); then
        printf 'Would back up %s -> %s\n' "$target" "$backup"
      else
        mkdir -p -- "$(dirname -- "$backup")"
        cp -a -- "$target" "$backup"
        BACKUP_CREATED=1
      fi
    fi

    if ((DRY_RUN)); then
      printf 'Would install %s -> %s with sudo\n' "$source" "$target"
    else
      sudo install -Dm0644 -- "$source" "$target"
    fi
  done < "$ROOT_DIR/manifest/system-files.txt"

  if ((DRY_RUN)); then
    echo "Would rebuild initramfs with: sudo mkinitcpio -P"
  else
    sudo mkinitcpio -P
  fi
}

apply_rice() {
  local selected_sprite errors

  ((APPLY_RICE)) || return 0
  if ((DRY_RUN)); then
    echo "Would apply Osaka Jade, restore the selected wallpaper, and reload the desktop"
    return
  fi

  OMARCHY_THEME_HEADLESS=1 omarchy theme set osaka-jade
  omarchy theme bg set "$HOME/.config/omarchy/backgrounds/osaka-jade/wallhaven-lyj56q_2560x1440.png"

  if command -v hyprctl >/dev/null 2>&1 && hyprctl instances >/dev/null 2>&1; then
    hyprctl reload >/dev/null
    errors="$(hyprctl configerrors 2>/dev/null || true)"
    if [[ -n "$errors" ]]; then
      echo "Hyprland reported configuration errors:" >&2
      echo "$errors" >&2
      exit 1
    fi
  fi

  omarchy restart terminal >/dev/null 2>&1 || true
  omarchy restart shell >/dev/null 2>&1 || true

  selected_sprite="$(< "$ROOT_DIR/state/fastfetch-current-sprite")"
  echo "Fastfetch starts with: $selected_sprite"
}

install_config_payload
install_fastfetch_assets
install_profile
install_system_branding
apply_rice

if ((DRY_RUN)); then
  echo "Dry run complete; nothing was changed."
elif ((BACKUP_CREATED)); then
  echo "Installed Osaka Jade rice v$(< "$ROOT_DIR/VERSION")."
  echo "Backups: $BACKUP_ROOT"
else
  echo "Installed Osaka Jade rice v$(< "$ROOT_DIR/VERSION") (no existing files needed backup)."
fi
