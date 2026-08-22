#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib/common
source "$SCRIPT_DIR/../scripts/install/lib/common"

MODE="plan"
KEEP_GAMING=false
GAMING_MANIFEST="$REPO_ROOT/packages/gaming.packages"
MISE_CONFIG_SOURCE="$REPO_ROOT/configs/base/.config/mise/config.toml"
MIMEAPPS_SOURCE="$REPO_ROOT/configs/base/.config/mimeapps.list"
SESSION_ENV_SOURCE="$REPO_ROOT/configs/base/.config/environment.d/90-dms.conf"
STALE_MANAGED_HOME_FILES=(
  ".config/autostart/jetbrains-toolbox.desktop"
  ".local/share/applications/jetbrains-toolbox.desktop"
)
SHARED_MANIFESTS=(
  "$REPO_ROOT/packages/base.packages"
  "$REPO_ROOT/packages/aur.packages"
  "$REPO_ROOT/packages/cachyos.packages"
  "$REPO_ROOT/packages/chaotic.packages"
)

COMMON_REMOVALS=(
  alacritty
  archinstall
  baobab
  bash-language-server
  cachyos-micro-settings
  cachyos-packageinstaller
  chromium
  cosmic-files
  curlie
  drawio-desktop
  fsarchiver
  gimp
  glances
  gnome-text-editor
  gopls
  helix
  httpie
  imv
  jetbrains-toolbox
  just
  kdenlive
  markdownlint
  micro
  mise
  npm
  octopi
  ollama
  opencode-desktop-bin
  papers
  shelly
  showtime
  solaar
  t3code-bin
  teams-for-linux
  typescript-language-server
  vim
  vlc-plugins-all
  vscode-css-languageserver
  vscode-html-languageserver
  vscode-json-languageserver
  vue-language-server
  yaml-language-server
  yazi
  zathura-cb
  zathura-djvu
  zen-browser-bin
  zls
  zoom
)

GAMING_REMOVALS=(
  cachyos-gaming-applications
  cachyos-gaming-meta
  dosbox
  gamescope
  goverlay
  heroic-games-launcher-bin
  lutris
  mangohud
  proton-cachyos-slr
  protontricks
  protonup-qt
  scummvm
  steam
  umu-launcher
  wine
  winetricks
  wowup-cf-bin
)

SYSTEM_NPM_REMOVALS=(
  @anthropic-ai/claude-code
  @openai/codex
  @xai-official/grok
  @vue/language-server
  bash-language-server
  svgo
  typescript
  typescript-language-server
  vscode-css-languageserver
  vscode-html-languageserver
  vscode-json-languageserver
  vscode-langservers-extracted
  yaml-language-server
)

PROTECTED_COMMON=(
  avahi
  cifs-utils
  cups
  cups-filters
  cups-pdf
  dms-shell
  dms-shell-niri
  greetd-dms-greeter-bin
  gutenprint
  hplip
  linux-cachyos
  linux-cachyos-headers
  linux-cachyos-lts
  linux-cachyos-lts-headers
  niri
  nix
  polkit-gnome
  power-profiles-daemon
  python
  python-pycups
  qt6-multimedia-ffmpeg
  quickshell-git
  smbclient
  swtpm
  wtype
  xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk
  xwayland-satellite
)

usage() {
  cat <<'EOF'
Usage: migrations/2026-08-19-common-baseline.sh [plan|apply] [--keep-gaming]

Commands:
  plan           Print the resolved Pacman removal transaction (default)
  apply          Back up state, install replacement tools, and run the removal

Options:
  --keep-gaming  Preserve the optional Niriland gaming profile

The migration never removes home-directory application data, game data,
containers, caches, or lib32 packages. Apply requires a typed confirmation and
leaves Pacman's own transaction confirmation enabled.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    plan)
      MODE="plan"
      ;;
    apply)
      MODE="apply"
      ;;
    --keep-gaming)
      KEEP_GAMING=true
      ;;
    help|-h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unexpected argument: $1"
      ;;
  esac
  shift
done

require_cmd pacman
require_cmd fakeroot
[[ -f "$GAMING_MANIFEST" ]] || die "Missing gaming manifest: $GAMING_MANIFEST"
[[ -f "$MISE_CONFIG_SOURCE" ]] || die "Missing mise config: $MISE_CONFIG_SOURCE"
[[ -f "$MIMEAPPS_SOURCE" ]] || die "Missing MIME applications config: $MIMEAPPS_SOURCE"
[[ -f "$SESSION_ENV_SOURCE" ]] || die "Missing graphical session environment: $SESSION_ENV_SOURCE"

declare -a removal_candidates=("${COMMON_REMOVALS[@]}")
declare -a removal_targets=()
declare -a resolved_removals=()
declare -a gaming_manifest_packages=()
declare -a protected_gaming=()
declare -a protected_packages=("${PROTECTED_COMMON[@]}")
declare -a installed_protected=()
declare -A protected_gaming_set=()
declare -A protected_package_set=()

for manifest in "${SHARED_MANIFESTS[@]}"; do
  [[ -f "$manifest" ]] || die "Missing shared package manifest: $manifest"
  mapfile -t manifest_packages < <(grep -Ev '^\s*(#|$)' "$manifest")
  protected_packages+=("${manifest_packages[@]}")
done

while IFS= read -r package_name; do
  case "$package_name" in
    lib32-*|foomatic-*|cups-*)
      protected_packages+=("$package_name")
      ;;
  esac
done < <(pacman -Qq)

if [[ "$KEEP_GAMING" == "false" ]]; then
  removal_candidates+=("${GAMING_REMOVALS[@]}")
else
  mapfile -t gaming_manifest_packages < <(grep -Ev '^\s*(#|$)' "$GAMING_MANIFEST")
  protected_gaming=("${GAMING_REMOVALS[@]}" "${gaming_manifest_packages[@]}" prismlauncher)

  for package_name in "${protected_gaming[@]}"; do
    protected_gaming_set["$package_name"]=1
  done

  protected_packages+=("${protected_gaming[@]}")
fi

for package_name in "${protected_packages[@]}"; do
  [[ -n "$package_name" ]] || continue
  protected_package_set["$package_name"]=1
done

for package_name in "${!protected_package_set[@]}"; do
  if pacman -Qq "$package_name" >/dev/null 2>&1; then
    installed_protected+=("$package_name")
  fi
done

for package_name in "${removal_candidates[@]}"; do
  if pacman -Qq "$package_name" >/dev/null 2>&1; then
    removal_targets+=("$package_name")
  fi
done

resolved_output=""
simulation_db=""
cleanup_simulation() {
  if [[ -n "${simulation_db:-}" && -d "$simulation_db" ]]; then
    find "$simulation_db" -depth -delete
  fi
}
trap cleanup_simulation EXIT

if [[ ${#removal_targets[@]} -eq 0 ]]; then
  log_success "No installed packages need removal for the selected baseline."
else
  simulation_db="$(mktemp -d)"
  cp -a /var/lib/pacman/local "$simulation_db/local"
  ln -s /var/lib/pacman/sync "$simulation_db/sync"
  if [[ ${#installed_protected[@]} -gt 0 ]]; then
    fakeroot pacman --dbpath "$simulation_db" -D --asexplicit "${installed_protected[@]}" >/dev/null
  fi

  if ! resolved_output="$(fakeroot pacman --dbpath "$simulation_db" -Rs --print-format '%n' -- "${removal_targets[@]}")"; then
    die "Pacman could not resolve the removal transaction."
  fi
  mapfile -t resolved_removals <<<"$resolved_output"

  for package_name in "${resolved_removals[@]}"; do
    [[ -n "$package_name" ]] || continue

    if [[ "$package_name" == lib32-* ]]; then
      die "Refusing transaction because it would remove protected package: $package_name"
    fi

    if [[ "$KEEP_GAMING" == "true" && -n "${protected_gaming_set[$package_name]:-}" ]]; then
      die "Refusing transaction because it would remove protected gaming package: $package_name"
    fi
  done
fi

log "Selected baseline: common"
if [[ "$KEEP_GAMING" == "true" ]]; then
  log "Machine exception: full gaming profile preserved"
else
  log "Machine exception: none"
fi

printf '\nDirect installed removal roots:\n'
if [[ ${#removal_targets[@]} -gt 0 ]]; then
  printf '  %s\n' "${removal_targets[@]}"
else
  printf '  (none)\n'
fi
printf '\nProtected baseline roots: %d installed packages\n' "${#installed_protected[@]}"
printf '\nResolved Pacman removal transaction:\n'
if [[ ${#resolved_removals[@]} -gt 0 ]]; then
  printf '  %s\n' "${resolved_removals[@]}"
else
  printf '  (none)\n'
fi

if [[ "$MODE" == "plan" ]]; then
  printf '\nPlan only. No files, packages, or system state were changed.\n'
  exit 0
fi

printf '\nApply replaces ~/.config/mise/config.toml with the tracked baseline.\n'
printf 'The current file is backed up and restored if mise installation fails.\n'
printf '\nType APPLY COMMON BASELINE to continue: '
read -r confirmation </dev/tty
[[ "$confirmation" == "APPLY COMMON BASELINE" ]] || die "Confirmation did not match; aborting."

require_cmd cargo
require_cmd curl
require_cmd awk
require_cmd sudo
sudo -v || die "sudo authentication failed"

timestamp="$(date +%Y%m%d%H%M%S)"
inventory_root="$HOME/.local/state/niriland/migrations/common-baseline-$timestamp"
mkdir -p "$inventory_root"

pacman -Qq >"$inventory_root/pacman-all.txt"
pacman -Qqe >"$inventory_root/pacman-explicit.txt"
pacman -Qqd >"$inventory_root/pacman-dependencies.txt"
pacman -Qqm >"$inventory_root/pacman-foreign.txt"
pacman -Qdtq >"$inventory_root/pacman-orphans.txt" || true
cargo install --list >"$inventory_root/cargo-install-list.txt"
if command -v mise >/dev/null 2>&1; then
  mise ls --global >"$inventory_root/mise-global.txt" 2>&1 || true
fi
if [[ -x /usr/bin/npm ]]; then
  env PATH=/usr/bin:/bin /usr/bin/npm --global list --depth=0 \
    >"$inventory_root/system-npm-global.txt" 2>&1 || true
fi
for relative_path in "${STALE_MANAGED_HOME_FILES[@]}"; do
  source_path="$HOME/$relative_path"
  if [[ -e "$source_path" || -L "$source_path" ]]; then
    backup_path="$inventory_root/home/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    cp -a "$source_path" "$backup_path"
  fi
done

mimeapps_target="$HOME/.config/mimeapps.list"
if [[ -f "$mimeapps_target" ]]; then
  mimeapps_backup="$inventory_root/home/.config/mimeapps.list"
  mkdir -p "$(dirname "$mimeapps_backup")"
  cp -a "$mimeapps_target" "$mimeapps_backup"
fi

session_env_target="$HOME/.config/environment.d/90-dms.conf"
if [[ -f "$session_env_target" ]]; then
  session_env_backup="$inventory_root/home/.config/environment.d/90-dms.conf"
  mkdir -p "$(dirname "$session_env_backup")"
  cp -a "$session_env_target" "$session_env_backup"
fi

mise_config_target="$HOME/.config/mise/config.toml"
mise_config_existed=false
mkdir -p "$(dirname "$mise_config_target")"
if [[ -f "$mise_config_target" ]]; then
  cp -a "$mise_config_target" "$inventory_root/mise-config.toml"
  mise_config_existed=true
fi

if command -v snapper >/dev/null 2>&1; then
  sudo snapper -c root create --description "Before Niriland common baseline migration"
else
  warn "snapper is unavailable; continuing with inventory but no filesystem snapshot."
fi

ensure_user_mise
cp -a "$MISE_CONFIG_SOURCE" "$mise_config_target"
if ! "$MISE_BIN" install; then
  if [[ "$mise_config_existed" == "true" ]]; then
    cp -a "$inventory_root/mise-config.toml" "$mise_config_target"
  else
    rm -f -- "$mise_config_target"
  fi
  die "Mise baseline installation failed; the pre-migration config state was restored."
fi

mise_node_npm="$("$MISE_BIN" which npm 2>/dev/null || true)"
if [[ -x "$mise_node_npm" ]] \
  && "$mise_node_npm" --global list --depth=0 @xai-official/grok >/dev/null 2>&1; then
  log "Removing the superseded Node-global Grok CLI."
  "$mise_node_npm" uninstall --global @xai-official/grok
fi

"$MISE_BIN" reshim
eval "$("$MISE_BIN" activate bash)"
install_baseline_cargo_tools
"$MISE_BIN" reshim

if [[ -x /usr/bin/npm ]]; then
  installed_system_npm=()
  for npm_package in "${SYSTEM_NPM_REMOVALS[@]}"; do
    if env PATH=/usr/bin:/bin /usr/bin/npm --global list --depth=0 "$npm_package" >/dev/null 2>&1; then
      installed_system_npm+=("$npm_package")
    fi
  done

  if [[ ${#installed_system_npm[@]} -gt 0 ]]; then
    log "Removing superseded system-global npm tools: ${installed_system_npm[*]}"
    sudo env PATH=/usr/bin:/bin /usr/bin/npm uninstall --global "${installed_system_npm[@]}"
  fi
fi

log "Marking reviewed baseline packages explicit so recursive cleanup preserves them."
if [[ ${#installed_protected[@]} -gt 0 ]]; then
  sudo pacman -D --asexplicit "${installed_protected[@]}"
fi

if [[ ${#removal_targets[@]} -gt 0 ]]; then
  if ! apply_resolved_output="$(pacman -Rs --print-format '%n' -- "${removal_targets[@]}")"; then
    die "Pacman could not re-resolve the removal transaction after protection."
  fi
  if [[ "$apply_resolved_output" != "$resolved_output" ]]; then
    die "Pacman transaction changed after planning; aborting before removal."
  fi

  log "Starting the reviewed Pacman removal transaction."
  sudo pacman -Rn -- "${resolved_removals[@]}"
else
  log "No Pacman removal transaction is needed; continuing baseline convergence."
fi

for relative_path in "${STALE_MANAGED_HOME_FILES[@]}"; do
  rm -f -- "$HOME/$relative_path"
done
log "Removed stale managed JetBrains Toolbox launchers."

log "Applying shared Snapper and Limine retention settings."
bash "$REPO_ROOT/scripts/install/steps/07-setup-snapper"

if [[ -f "$mimeapps_target" ]]; then
  mimeapps_tmp="$(mktemp)"
  awk '
    /^\[Default Applications\]$/ {
      in_defaults = 1
      print
      next
    }
    /^\[/ {
      in_defaults = 0
    }
    in_defaults && /^(image\/vnd\.djvu|application\/x-cb[7rtz])=/ {
      next
    }
    in_defaults {
      gsub(/org\.gnome\.Showtime\.desktop/, "mpv.desktop")
      gsub(/org\.gnome\.TextEditor\.desktop/, "dev.zed.Zed.desktop")
    }
    { print }
  ' "$mimeapps_target" >"$mimeapps_tmp"
  chmod --reference="$mimeapps_target" "$mimeapps_tmp"
  mv -f -- "$mimeapps_tmp" "$mimeapps_target"
else
  mkdir -p "$(dirname "$mimeapps_target")"
  cp -a "$MIMEAPPS_SOURCE" "$mimeapps_target"
fi
log "Updated MIME defaults for the retained application baseline."

mkdir -p "$(dirname "$session_env_target")"
cp -a "$SESSION_ENV_SOURCE" "$session_env_target"
log "Added mise shims to the graphical session PATH; log out and back in to activate it."

[[ -x "$HOME/.local/bin/mise" ]] || die "User-local mise is missing after migration."
log_success "Common baseline migration completed. Inventory: $inventory_root"
