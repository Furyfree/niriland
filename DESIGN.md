# Niriland Installer Design

This document describes the current implementation in this repository.

## Entry Points

### `bootstrap`
- Clones or updates the repo to `NIRILAND_DIR` (default: `~/.local/share/niriland`).
- Uses `NIRILAND_REPO_URL` when set (default: `https://github.com/Furyfree/niriland.git`).
- Executes `install` from the cloned repo.

### `install`
- Sources shared helpers from:
  - `scripts/install/lib/common`
  - `scripts/install/lib/options`
- Collects:
  - sudo password (`read_system_pass`)
  - disk encryption password (`read_luks_pass`)
  - git user/email (`read_git_config`, `setup_git_user`)
- Builds an ordered step list and runs each executable step script.
- Cleans up credentials/cache at the end via `cleanup_all`.

## Recommended Archinstall Baseline

Template file:
- `configs/system/archinstall/recommended.json`

Baseline intent:
- Minimal profile
- Limine bootloader
- Btrfs + Snapper subvolumes
- LUKS encryption
- `nm_iwd` networking
- PipeWire + Bluetooth + print service enabled

Fields expected to be customized per machine/location:
- `disk_config.device_modifications[].device`
- `hostname`
- `locale_config.kb_layout`
- `mirror_config.mirror_regions`
- `timezone`

## Install Options

These are implemented in `scripts/install/lib/options`:

- `NIRILAND_INSTALL_GAMING`:
  - true values: `1`, `true`, `yes`, `y` (case-insensitive variants included)
  - otherwise false
  - if unset: interactive prompt (default: `No`)
- `NIRILAND_INSTALL_AI`:
  - true values: `1`, `true`, `yes`, `y` (case-insensitive variants included)
  - otherwise false
  - if unset: interactive prompt (default: `No`)

AI model overrides used by `65-setup-ai`:
- `NIRILAND_OLLAMA_MODEL_NVIDIA` (default: `qwen2.5-coder:14b`)
- `NIRILAND_OLLAMA_MODEL_CPU` (default: `qwen2.5-coder:3b`)

## Step Order

Current `install` execution order:

1. `00-setup-pacman`
2. `05-setup-fde`
3. `10-install-drivers`
4. `15-install-packages`
5. `17-setup-dms`
6. `20-deploy-configs`
7. `25-setup-theming`
8. `30-setup-shell`
9. `32-setup-keyring`
10. `35-setup-tools`
11. `40-setup-gaming` (optional)
12. `45-setup-dev`
13. `50-setup-browser`
14. `55-setup-vm`
15. `60-setup-certificates`
16. `65-setup-ai` (optional)
17. `70-setup-desktop-entries`
18. `85-optimize-system`
19. `99-post-install`

## Step Responsibilities

### `00-setup-pacman`
- Deploys `configs/system/etc/pacman.conf` to `/etc/pacman.conf`.
- Configures Chaotic AUR keyring + repo if missing.
- Installs `paru` and enables `paccache.timer`.

### `05-setup-fde`
- Configures TPM2 auto-unlock for existing LUKS2 root.
- Writes:
  - `/etc/mkinitcpio.conf.d/fde-systemd.conf`
  - `/etc/kernel/cmdline`
  - `/etc/crypttab.initramfs`
- Enrolls recovery key and TPM2 token when missing.
- Runs `limine-update`.

### `10-install-drivers`
- Detects GPU vendor(s) via `lspci`.
- Installs Vulkan + vendor-specific driver packages.

### `15-install-packages`
- Installs package sets from:
  - `packages/base.packages`
  - `packages/chaotic.packages`
  - `packages/aur.packages`

### `17-setup-dms`
- Installs DMS and dependencies.
- Adds user wants for `dms` under `niri.service`.

### `20-deploy-configs`
- Copies `configs/base/*` to `$HOME/*` with backups.
- Skips unchanged files and placeholders.

### `25-setup-theming`
- Applies `gsettings` interface/font preferences (best effort).
- Syncs wallpapers from `configs/backgrounds` to `~/Pictures/Wallpapers`.
- Sets a random wallpaper through `dms ipc` when available.

### `30-setup-shell`
- Ensures `zsh` is installed.
- Sets default shell for target user.

### `32-setup-keyring`
- Installs GNOME keyring packages.
- Ensures PAM lines for keyring auto-unlock.

### `35-setup-tools`
- Syncs `scripts/tools/*` to `~/.local/bin/niriland`.
- Ensures PATH entries in `~/.zprofile` and `~/.profile`.

### `40-setup-gaming` (optional)
- Installs gaming packages (Steam, launchers, etc.).

### `45-setup-dev`
- Installs and enables Docker.
- Adds target user to required groups.
- Installs mise + platformio-core.
- Installs PlatformIO udev rules when missing.

### `50-setup-browser`
- Installs browser dependencies:
  - `helium-browser-bin`
  - `chromium-widevine`
  - `1password`
- Links Widevine into Helium.
- Allows `helium` in `/etc/1password/custom_allowed_browsers`.

### `55-setup-vm`
- Installs `vmware-workstation`.
- Enables and starts:
  - `vmware-networks.service`
  - `vmware-usbarbitrator.service`
- Treats VMware service setup as best-effort:
  - warns and continues if a unit is missing or service start fails.

### `60-setup-certificates`
- Copies `configs/system/etc/certs/Eduroam_aug2020.pem` to `/etc/certs/`.
- Runs `update-ca-trust`.

### `65-setup-ai` (optional)
- Installs Opencode and Codex only when missing.
- Installs/enables Ollama and Docker.
- Detects NVIDIA and chooses:
  - NVIDIA service template + CUDA OpenWebUI image + larger model
  - CPU service template + CPU OpenWebUI image + smaller model
- Uses templates from `configs/system/etc/systemd/system/`.

### `70-setup-desktop-entries`
- Syncs:
  - `configs/base/.local/share/applications` -> `~/.local/share/applications`
  - `configs/base/.local/share/icons` -> `~/.local/share/icons`
  - `configs/base/.local/share/icons` -> `~/.local/share/pixmaps`
- Applies `configs/base/.local/share/applications/hidden/*.desktop` as overrides in `~/.local/share/applications/`.
- Skips unchanged files/symlinks.

### `85-optimize-system`
- Enables `fstrim.timer` if present.
- Enables `paccache.timer` if present.

### `99-post-install`
- Refreshes font cache.
- Refreshes desktop entry database.
- Refreshes icon cache for local hicolor theme when present.
- Prints logout/reboot reminder.

## Shared Paths

- User configs: `configs/base/`
- System configs: `configs/system/`
- Package lists: `packages/*.packages`
- Install steps: `scripts/install/steps/*`
- Shared functions: `scripts/install/lib/common`

## Design Constraints

- Steps are designed to be idempotent where practical.
- The installer assumes Arch Linux + systemd + sudo access.
- `05-setup-fde` expects an existing encrypted root setup when TPM is present.
- Some theming/session actions are best-effort if no active desktop session is available.
