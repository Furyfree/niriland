#!/usr/bin/env bash

set -euo pipefail

NIRILAND_ROOT="$HOME/.local/share/niriland"
BACKUP_ROOT="$HOME/.config/backups/niriland/migrations/$(date +%Y%m%d%H%M%S)"
CONFIG_PATHS=(
  ".config/VSCodium/User/settings.json"
  ".config/VSCodium/User/keybindings.json"
)

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

for rel_path in "${CONFIG_PATHS[@]}"; do
  src="$NIRILAND_ROOT/configs/base/$rel_path"
  dest="$HOME/$rel_path"

  [[ -f "$src" ]] || die "Missing source config file: $src"

  mkdir -p "$(dirname "$dest")"

  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    log "$dest is already current."
    continue
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_path="$BACKUP_ROOT/$rel_path"
    mkdir -p "$(dirname "$backup_path")"
    log "Backing up $dest -> $backup_path"
    cp -a "$dest" "$backup_path"
  fi

  log "Copying VSCodium config from $src"
  cp -a "$src" "$dest"
done

log "Restart or reload VSCodium to pick up the layout changes."
