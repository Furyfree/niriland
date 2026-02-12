# Niriland Installer Design

This document describes the implementation currently in this repository.

## Entry Points

### `bootstrap`

- Requires `git`.
- Clones/updates the repo to `NIRILAND_DIR` (default `~/.local/share/niriland`).
- Uses `NIRILAND_REPO_URL` when set (default `https://github.com/Furyfree/niriland.git`).
- Runs `install` from the target repo.

### `install`

- Sources `scripts/install/lib/common`.
- Prompts for and validates:
- sudo password (`read_system_pass`)
- LUKS password (`read_luks_pass`, empty input reuses sudo password)
- git config (`read_git_config`, `setup_git_user`)
- Executes numbered step scripts in a fixed order.
- Calls `cleanup_all` at the end, which runs:
- `sudo -k`
- `clean_git_config`
- `clean_cache` (`paccache -r` via sudo)
- `clean_system_pass`
- `clean_luks_pass`

### `scripts/tools/niriland-update`

- Resolves repo root from script location, then `$PWD`, then `NIRILAND_DIR`.
- Requires a clean git worktree (`git diff-index --quiet HEAD --`).
- Pulls latest changes with `git pull --ff-only`.
- Prompts for sudo password.
- Runs step subsets in this order: `15-*`, `20-*`, `35-*`, `70-*`, `99-*`.
- Runs `20-*` with `NIRILAND_CONFIG_DEPLOY_MODE=preserve`.
- If `cargo-install-update` exists, runs `cargo install-update --all`.
- Clears cached sudo password with `clean_system_pass`.

## Installer Step Order

Current `install` order:

1. `00-setup-pacman`
2. `05-setup-fde`
3. `10-install-drivers`
4. `15-install-packages`
5. `17-setup-dms`
6. `20-deploy-configs`
7. `25-setup-backgrounds`
8. `28-setup-theming`
9. `30-setup-shell`
10. `32-setup-keyring`
11. `35-setup-tools`
12. `36-setup-lazyvim`
13. `45-setup-dev`
14. `46-setup-vscodium`
15. `50-setup-browser`
16. `70-setup-desktop-entries`
17. `85-optimize-system`
18. `99-post-install`

## Step Responsibilities

### `00-setup-pacman`

- Installs `base-devel`.
- Deploys `configs/system/etc/pacman.conf` to `/etc/pacman.conf`.
- Configures Chaotic AUR keyring/repo if missing.
- Installs `paru`.
- Enables `BottomUp`, `SudoLoop`, `CombinedUpgrade`, `UpgradeMenu`, `NewsOnUpgrade`, and `SkipReview` in `/etc/paru.conf`.
- Installs `pacman-contrib` and enables `paccache.timer`.

### `05-setup-fde`

- Exits early when no TPM device exists (`/dev/tpmrm0` or `/dev/tpm0`).
- Installs `limine-mkinitcpio-hook` and `limine-snapper-sync`.
- Detects root mapper and validates LUKS2.
- Writes:
- `/etc/mkinitcpio.conf.d/fde-systemd.conf`
- `/etc/kernel/cmdline`
- `/etc/crypttab.initramfs`
- Enrolls systemd recovery key and TPM2 token when missing.
- Stores recovery key at `/root/luks-recovery-key.txt`.
- Runs `limine-update`.
- Removes `/boot/limine` if present.

### `10-install-drivers`

- Installs `pciutils`, requires `lspci`.
- Detects AMD/Intel/NVIDIA GPU vendors from PCI IDs.
- Builds a deduplicated install list for Vulkan + vendor packages.
- Runs `limine-update` after driver install.

### `15-install-packages`

- Reads:
- `packages/base.packages`
- `packages/chaotic.packages`
- `packages/aur.packages`
- Installs base + chaotic lists via pacman helper.
- Installs AUR list via `paru`.

### `17-setup-dms`

- Installs DMS/Niri runtime dependencies and `dms-shell-bin`.
- Ensures `greeter` group exists and target user is a member.
- Tries `systemctl --user add-wants niri.service dms`.
- Requires `dms`, then runs:
- `dms greeter enable`
- `dms greeter sync`
- Emits warnings (not hard failure) when no active user session is available for user-service actions.

### `20-deploy-configs`

- Copies `configs/base/*` to `$HOME/*`.
- Skips unchanged files/symlinks and `PLACEHOLDER` markers.
- Backs up replaced paths to `~/.config/backups/niriland/<timestamp>/...`.
- Supports deploy mode via `NIRILAND_CONFIG_DEPLOY_MODE`:
- `overwrite` (default)
- `preserve` (skip overwriting existing `~/.config/*` entries)

### `25-setup-backgrounds`

- Syncs `configs/backgrounds/*` to `~/Pictures/Wallpapers`.
- Skips unchanged files.

### `28-setup-theming`

- Requires `gsettings`.
- Sets GTK theme, icon theme, cursor, font settings, and font rendering options.
- Skips keys already set to desired value.

### `30-setup-shell`

- Installs `zsh`.
- Sets target user shell to `zsh` (`chsh`).

### `32-setup-keyring`

- Installs `gnome-keyring`, `libsecret`, `seahorse`.
- Ensures PAM lines for keyring integration in:
- `/etc/pam.d/greetd` or `/etc/pam.d/login`
- `/etc/pam.d/passwd`

### `35-setup-tools`

- Copies `scripts/tools/*` to `~/.local/bin/niriland`.
- Ensures executables are `+x`.
- Appends PATH block to `~/.zprofile` and `~/.profile` (once).

### `36-setup-lazyvim`

- Skips if LazyVim already appears installed.
- Backs up existing Neovim dirs with timestamp suffixes.
- Clones `https://github.com/LazyVim/starter` into `~/.config/nvim`.
- Removes starter `.git`.

### `45-setup-dev`

- Installs/enables Docker services.
- Adds user to `docker`, `uucp`, and `lock` groups when needed.
- Installs `mise` and runs `mise install` if `~/.config/mise/config.toml` exists.
- Installs `platformio-core`.
- Installs PlatformIO udev rules from upstream URL if missing.
- Requires `cargo`, installs `cargo-update` and `nirius`.
- Symlinks `nirius`/`niriusd` into `~/.local/bin` when available in `~/.cargo/bin`.

### `46-setup-vscodium`

- Requires `codium`.
- Reads `packages/vscodium.extensions`.
- Skips blank/comment entries and already-installed extensions.
- Installs missing extensions and reports installed/skipped/failed totals.

### `50-setup-browser`

- Installs `helium-browser-bin`, `chromium-widevine`, and AUR `1password`.
- Symlinks Chromium Widevine into Helium.
- Writes `/etc/1password/custom_allowed_browsers` with `helium`.
- Sets default browser/MIME associations when `xdg-settings` and `xdg-mime` exist.

### `70-setup-desktop-entries`

- Deploys top-level desktop entries from `configs/base/.local/share/applications`.
- Applies `configs/base/.local/share/applications/hidden/*` as overrides.
- Restarts DMS if desktop entries changed and user service restart is available.
- Deploys icon files from `configs/base/.local/share/icons` to local hicolor path.
- Copies `/usr/share/icons/hicolor/index.theme` into local hicolor tree when present.
- Refreshes icon cache when `gtk-update-icon-cache` exists.

### `85-optimize-system`

- Enables `fstrim.timer` when unit exists.
- Enables `paccache.timer` when unit exists.

### `99-post-install`

- Requires `dms` and `limine-snapper-sync`.
- Refreshes font cache (`fc-cache`).
- Refreshes desktop database when `~/.local/share/applications` exists.
- Refreshes local hicolor icon cache when local hicolor theme exists.
- Restarts DMS via `dms restart` when available.
- Runs `limine-snapper-sync` via sudo.
- Emits reboot/logout and fingerprint setup reminders.

## Helper Tools (Manual/On-Demand)

Installed by `35-setup-tools` into `~/.local/bin/niriland`:

- `niriland-update`: partial update flow.
- `niriland-setup-ai`: installs Opencode/Codex/Ollama/OpenWebUI and chooses CPU vs NVIDIA service/image.
- `niriland-setup-gaming`: installs gaming stack and optionally imports PrismLauncher pack.
- `niriland-setup-certificates`: installs `Eduroam_aug2020.pem` and runs `update-ca-trust`.
- `niriland-setup-fingerprint`: configures/removes fingerprint auth PAM changes.
- `niriland-vm-libvirt`: installs/configures libvirt/qemu.
- `niriland-vm-vmware`: installs/configures VMware services.
- `niriland-get-default-browser`: prints app-id matcher.
- `niriland-launch-browser`: launches default browser with private-mode flag mapping.
- `niriland-launch-webapp`: launches URL as browser app window.

## Data and Path Model

- User-deployed config root: `configs/base/`.
- Shared modular config fragments: `configs/modules/`.
- System assets: `configs/system/`.
- Package manifests: `packages/*.packages`.
- VSCodium extension manifest: `packages/vscodium.extensions`.
- Installer steps: `scripts/install/steps/`.
- Shared helper library: `scripts/install/lib/common`.

Niri path coupling:

- `configs/base/.config/niri/config.kdl` includes `../../.local/share/niriland/configs/modules/.config/niri/config.kdl`.
- Default `bootstrap` location satisfies this include path.
- If repo lives elsewhere, this include path must be adjusted.

## Environment Variables

- `NIRILAND_REPO_URL`: bootstrap clone URL override.
- `NIRILAND_DIR`: bootstrap/update fallback repo location.
- `NIRILAND_CONFIG_DEPLOY_MODE`: config deployment mode (`overwrite` or `preserve`).
- `NIRILAND_OLLAMA_MODEL_NVIDIA`: AI setup NVIDIA model override.
- `NIRILAND_OLLAMA_MODEL_CPU`: AI setup CPU model override.

## Design Constraints

- Target platform is Arch Linux with `systemd` and `sudo`.
- Steps aim for safe re-runs (check-before-copy/install where practical).
- `05-setup-fde` assumes existing LUKS2 root and TPM when auto-unlock is configured.
- Some user-session actions depend on a running user systemd session and degrade to warnings when unavailable.
- VM/gaming/AI/cert/fingerprint setup remains opt-in via helper tools, not default installer steps.
