#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE="$REPO_ROOT/configs/base"

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

sudo_cmd() {
  sudo "$@"
}

copy_if_changed() {
  local src="$1"
  local dest="$2"

  [[ -e "$src" ]] || die "Missing source file: $src"
  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" ]] && cmp -s "$src" "$dest"; then
    log "$dest is already current."
    return 0
  fi

  log "Copying $src to $dest."
  cp -a "$src" "$dest"
}

remove_npm_global_if_present() {
  local npm_bin="$1"
  local package="$2"
  shift 2

  if "$npm_bin" list -g --depth=0 "$@" "$package" >/dev/null 2>&1; then
    log "Removing $package from $("$npm_bin" prefix -g "$@" 2>/dev/null || printf 'global npm')."
    "$npm_bin" uninstall -g "$@" "$package"
  else
    log "$package is not installed in $("$npm_bin" prefix -g "$@" 2>/dev/null || printf 'global npm'), skipping."
  fi
}

install_system_npm_global() {
  local package="$1"

  require_cmd /usr/bin/npm
  log "Installing/updating $package with system npm."
  sudo_cmd env PATH=/usr/bin:/bin /usr/bin/npm install -g "${package}@latest"
}

refresh_shell_lookup() {
  hash -r 2>/dev/null || true
}

expect_binary_path() {
  local binary="$1"
  local expected="$2"
  local actual

  actual="$(command -v "$binary" || true)"
  if [[ "$actual" != "$expected" ]]; then
    die "$binary resolves to ${actual:-<not found>}, expected $expected"
  fi
}

migrate_claude_code_to_system_npm() {
  log "Migrating Claude Code to system npm."
  require_cmd npm

  remove_npm_global_if_present npm @anthropic-ai/claude-code
  remove_npm_global_if_present npm @anthropic-ai/claude-code --prefix "$HOME/.local"
  install_system_npm_global @anthropic-ai/claude-code

  refresh_shell_lookup
  expect_binary_path claude /usr/bin/claude
  claude --version
}

remove_local_openwebui_docker() {
  log "Removing local OpenWebUI Docker instance if present."

  if systemctl list-unit-files --no-legend openwebui.service 2>/dev/null | grep -q '^openwebui.service'; then
    sudo_cmd systemctl disable --now openwebui.service
  else
    log "openwebui.service is not installed, skipping service disable."
  fi

  if [[ -e /etc/systemd/system/openwebui.service ]]; then
    sudo_cmd rm -f /etc/systemd/system/openwebui.service
    sudo_cmd systemctl daemon-reload
  else
    log "/etc/systemd/system/openwebui.service is already absent."
  fi

  sudo_cmd systemctl reset-failed openwebui.service 2>/dev/null || true

  if ! command -v docker >/dev/null 2>&1; then
    log "docker is not installed, skipping Docker cleanup."
    return 0
  fi

  sudo_cmd systemctl start docker.service

  if sudo_cmd docker ps -a --format '{{.Names}}' | grep -Fxq open-webui; then
    sudo_cmd docker rm -f open-webui
  else
    log "open-webui container is already absent."
  fi

  local image
  for image in \
    ghcr.io/open-webui/open-webui:main \
    ghcr.io/open-webui/open-webui:cuda
  do
    if sudo_cmd docker image inspect "$image" >/dev/null 2>&1; then
      sudo_cmd docker image rm "$image"
    else
      log "$image is already absent."
    fi
  done

  if sudo_cmd docker volume ls -q | grep -Fxq open-webui; then
    sudo_cmd docker volume rm open-webui
  else
    log "open-webui Docker volume is already absent."
  fi
}

remove_local_vm_tooling() {
  log "Removing local VM tooling if present."

  local unit
  for unit in \
    libvirtd.service \
    libvirtd.socket \
    virtlogd.socket \
    virtlockd.socket
  do
    if systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q "^${unit}"; then
      sudo_cmd systemctl disable --now "$unit" || true
    else
      log "$unit is not installed, skipping."
    fi
    sudo_cmd systemctl reset-failed "$unit" 2>/dev/null || true
  done

  if command -v virsh >/dev/null 2>&1; then
    if sudo_cmd virsh net-info default >/dev/null 2>&1; then
      if sudo_cmd virsh net-list --name | grep -Fxq default; then
        sudo_cmd virsh net-destroy default || true
      fi

      sudo_cmd virsh net-autostart default --disable || true
    fi
  fi

  local target_user="${SUDO_USER:-${USER:-}}"
  if [[ -n "$target_user" ]] && getent group libvirt >/dev/null 2>&1 && id -nG "$target_user" | grep -qw libvirt; then
    sudo_cmd gpasswd -d "$target_user" libvirt || true
  fi

  local -a vm_packages=(
    quickgui
    quickemu-git
    virt-manager
    qemu-full
    swtpm
  )
  local -a installed_vm_packages=()
  local package
  for package in "${vm_packages[@]}"; do
    if pacman -Qq "$package" >/dev/null 2>&1; then
      installed_vm_packages+=("$package")
    fi
  done

  if [[ ${#installed_vm_packages[@]} -gt 0 ]]; then
    sudo_cmd pacman -Rns --noconfirm "${installed_vm_packages[@]}"
  else
    log "VM packages are already absent."
  fi

  if [[ -f /etc/libvirt/network.conf ]] && grep -Fxq 'firewall_backend = "iptables"' /etc/libvirt/network.conf; then
    sudo_cmd sed -i '/^firewall_backend = "iptables"$/d' /etc/libvirt/network.conf
  fi

  local empty_dir
  for empty_dir in \
    "$HOME/.config/libvirt" \
    /var/log/libvirt \
    /etc/libvirt
  do
    if [[ -d "$empty_dir" ]]; then
      sudo_cmd rmdir "$empty_dir" 2>/dev/null || log "$empty_dir is not empty, leaving it in place."
    fi
  done
}

refresh_codex_desktop_entry() {
  copy_if_changed \
    "$BASE/.local/share/applications/Codex.desktop" \
    "$HOME/.local/share/applications/Codex.desktop"
}

stabilize_topgrade_and_helix() {
  log "Refreshing Topgrade and Helix config."
  copy_if_changed "$BASE/.config/topgrade.toml" "$HOME/.config/topgrade.toml"
  copy_if_changed "$BASE/.config/helix/languages.toml" "$HOME/.config/helix/languages.toml"

  if [[ -d "$HOME/.config/helix/runtime/grammars/sources/gotmpl" ]]; then
    log "Removing stale Helix gotmpl grammar source."
    rm -rf -- "$HOME/.config/helix/runtime/grammars/sources/gotmpl"
  else
    log "Stale Helix gotmpl grammar source is already absent."
  fi

  if command -v helix >/dev/null 2>&1; then
    helix --grammar fetch
    helix --grammar build
  else
    warn "helix is not installed, skipping grammar refresh."
  fi

  if command -v topgrade >/dev/null 2>&1; then
    topgrade --dry-run --config "$HOME/.config/topgrade.toml" --only helix --no-ask-retry
    topgrade --dry-run --config "$HOME/.config/topgrade.toml" --only containers --no-ask-retry
  else
    warn "topgrade is not installed, skipping dry-run verification."
  fi
}

refresh_zed_feature_flags() {
  copy_if_changed "$BASE/.config/zed/settings.json" "$HOME/.config/zed/settings.json"
}

replace_evince_with_zathura() {
  log "Installing Zathura package set."
  require_cmd pacman

  sudo_cmd pacman -S --needed --noconfirm \
    zathura \
    zathura-pdf-mupdf \
    zathura-cb \
    zathura-djvu \
    tesseract-data-eng

  local -a remove_packages=()
  local package
  for package in evince sushi; do
    if pacman -Qq "$package" >/dev/null 2>&1; then
      remove_packages+=("$package")
    fi
  done

  if [[ ${#remove_packages[@]} -gt 0 ]]; then
    sudo_cmd pacman -Rns --noconfirm "${remove_packages[@]}"
  else
    log "Evince/Sushi are already absent."
  fi

  copy_if_changed "$BASE/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
  xdg-mime query default application/pdf
}

migrate_limine_save_commands_to_boot_hooks() {
  log "Migrating Limine save commands to boot hooks."

  sudo_cmd mkdir -p /etc/boot/hooks/pre.d /etc/boot/hooks/post.d

  if sudo_cmd test -f /etc/limine-snapper-sync.conf; then
    if sudo_cmd grep -q '^MAX_SNAPSHOT_ENTRIES=' /etc/limine-snapper-sync.conf; then
      sudo_cmd sed -i 's|^MAX_SNAPSHOT_ENTRIES=.*$|MAX_SNAPSHOT_ENTRIES=15|' /etc/limine-snapper-sync.conf
    else
      printf '%s\n' 'MAX_SNAPSHOT_ENTRIES=15' | sudo_cmd tee -a /etc/limine-snapper-sync.conf >/dev/null
    fi
  fi

  if [[ -x /usr/bin/limine-reset-enroll ]]; then
    if sudo_cmd test -e /etc/boot/hooks/pre.d/10-limine-reset-enroll && ! sudo_cmd test -L /etc/boot/hooks/pre.d/10-limine-reset-enroll; then
      warn "/etc/boot/hooks/pre.d/10-limine-reset-enroll exists and is not a symlink, leaving it unchanged."
    else
      sudo_cmd ln -sfn /usr/bin/limine-reset-enroll /etc/boot/hooks/pre.d/10-limine-reset-enroll
    fi
  else
    warn "/usr/bin/limine-reset-enroll is missing, skipping pre-save hook."
  fi

  if [[ -x /usr/bin/limine-enroll-config ]]; then
    if sudo_cmd test -e /etc/boot/hooks/post.d/90-limine-enroll-config && ! sudo_cmd test -L /etc/boot/hooks/post.d/90-limine-enroll-config; then
      warn "/etc/boot/hooks/post.d/90-limine-enroll-config exists and is not a symlink, leaving it unchanged."
    else
      sudo_cmd ln -sfn /usr/bin/limine-enroll-config /etc/boot/hooks/post.d/90-limine-enroll-config
    fi
  else
    warn "/usr/bin/limine-enroll-config is missing, skipping post-save hook."
  fi

  local file
  local deprecated_found=0
  for file in /etc/default/limine /etc/limine-snapper-sync.conf; do
    if sudo_cmd test -f "$file"; then
      sudo_cmd sed -i \
        -e '/^COMMANDS_BEFORE_SAVE=.*$/d' \
        -e '/^COMMANDS_AFTER_SAVE=.*$/d' \
        "$file"

      if sudo_cmd grep -Eq '^COMMANDS_(BEFORE|AFTER)_SAVE=' "$file"; then
        warn "$file still contains deprecated Limine save command settings."
        deprecated_found=1
      fi
    fi
  done

  [[ "$deprecated_found" -eq 0 ]] || die "Deprecated Limine save command settings remain."

  if command -v limine-snapper-sync >/dev/null 2>&1; then
    sudo_cmd limine-snapper-sync
  fi
}

migrate_codex_to_system_npm() {
  log "Migrating Codex CLI to system npm."
  require_cmd npm

  remove_npm_global_if_present npm @openai/codex
  remove_npm_global_if_present npm @openai/codex --prefix "$HOME/.local"
  install_system_npm_global @openai/codex

  refresh_shell_lookup
  expect_binary_path codex /usr/bin/codex
  codex --version
}

verify() {
  log "Verification."

  if command -v ollama >/dev/null 2>&1; then
    systemctl is-active ollama || true
    ollama list || true
  fi

  if command -v codex >/dev/null 2>&1; then
    type -a codex || true
    which codex || true
    codex --version || true
  fi

  if command -v claude >/dev/null 2>&1; then
    type -a claude || true
    which claude || true
    claude --version || true
  fi

  if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime query default application/pdf || true
  fi

  if [[ -f "$HOME/.config/topgrade.toml" ]]; then
    grep -n '^disable =' "$HOME/.config/topgrade.toml" || true
  fi
}

main() {
  require_cmd sudo
  require_cmd grep
  require_cmd cmp
  require_cmd cp

  sudo_cmd -v

  migrate_claude_code_to_system_npm
  remove_local_openwebui_docker
  remove_local_vm_tooling
  refresh_codex_desktop_entry
  stabilize_topgrade_and_helix
  refresh_zed_feature_flags
  replace_evince_with_zathura
  migrate_limine_save_commands_to_boot_hooks
  migrate_codex_to_system_npm
  verify

  log "30. april 2026 migrations completed."
}

main "$@"
