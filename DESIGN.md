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

## Optional Tool Overrides

AI model overrides used by `scripts/tools/niriland-setup-ai`:

- `NIRILAND_OLLAMA_MODEL_NVIDIA` (default: `qwen2.5-coder:14b`)
- `NIRILAND_OLLAMA_MODEL_CPU` (default: `qwen2.5-coder:3b`)

## Step Order

Current `install` execution order:

1. `00-setup-pacman`
2. `01-setup-dms`
3. `05-setup-fde`
4. `10-install-drivers`
5. `15-install-packages`
6. `20-deploy-configs`
7. `25-setup-backgrounds`
8. `28-setup-theming`
9. `30-setup-shell`
10. `32-setup-keyring`
11. `35-setup-tools`
12. `36-setup-lazyvim`
13. `45-setup-dev`
14. `50-setup-browser`
15. `70-setup-desktop-entries`
16. `85-optimize-system`
17. `99-post-install`

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

### `01-setup-dms`

- Installs DMS and dependencies.
- Adds user wants for `dms` under `niri.service`.

### `20-deploy-configs`

- Copies `configs/base/*` to `$HOME/*` with backups.
- Skips unchanged files and placeholders.

### `25-setup-backgrounds`

- Syncs backgrounds from `configs/backgrounds` to `~/Pictures/Wallpapers`.

### `28-setup-theming`

- Applies desktop theming via `gsettings` (GTK, icon, cursor, fonts, and font rendering options).
- Skips values that are already set.

### `30-setup-shell`

- Ensures `zsh` is installed.
- Sets default shell for target user.

### `32-setup-keyring`

- Installs GNOME keyring packages.
- Ensures PAM lines for keyring auto-unlock.

### `35-setup-tools`

- Syncs `scripts/tools/*` to `~/.local/bin/niriland`.
- Ensures PATH entries in `~/.zprofile` and `~/.profile`.

### `36-setup-lazyvim`

- Skips setup when an existing LazyVim config is already detected.
- Backs up existing Neovim directories under `~/.config`, `~/.local/share`, `~/.local/state`, and `~/.cache`.
- Clones `https://github.com/LazyVim/starter` into `~/.config/nvim` and removes its `.git` directory.

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

### Virtualization (manual tools)

- VM stacks are opt-in and not run during default install.
- Available helper tools under `scripts/tools/`:
  - `niriland-vm-libvirt`
  - `niriland-vm-vmware`

### Gaming (manual tool)

- `scripts/tools/niriland-setup-gaming` installs gaming packages (Steam, launchers, etc.).

### Certificates (manual tool)

- `scripts/tools/niriland-setup-certificates` copies `configs/system/etc/certs/Eduroam_aug2020.pem` to `/etc/certs/`.
- Refreshes trust store with `update-ca-trust`.

### AI (manual tool)

- `scripts/tools/niriland-setup-ai` installs Opencode and Codex only when missing.
- Installs/enables Ollama and Docker.
- Detects NVIDIA and chooses:
  - NVIDIA service template + CUDA OpenWebUI image + larger model
  - CPU service template + CPU OpenWebUI image + smaller model
- Uses templates from `configs/system/etc/systemd/system/`.

### `70-setup-desktop-entries`

- Copies top-level desktop entries from `configs/base/.local/share/applications` to `~/.local/share/applications`.
- Applies `configs/base/.local/share/applications/hidden/*.desktop` as overrides in `~/.local/share/applications/`.
- Copies icon files from `configs/base/.local/share/icons` to `~/.local/share/icons/hicolor/256x256/apps/`.
- Copies `/usr/share/icons/hicolor/index.theme` to `~/.local/share/icons/hicolor/index.theme`.
- Runs `gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` when available.
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
- VM setup is intentionally manual via helper tools.
