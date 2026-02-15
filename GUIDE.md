# Niriland Guide

Practical reference for using and maintaining a Niriland setup.

## What Niriland Is

Niriland is an Arch Linux setup around:

- Niri compositor
- DankMaterialShell (DMS)
- Curated package manifests
- User/system config deployment
- Optional helper scripts for extra capabilities

## Warnings

- This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
- Step `05-setup-fde` enrolls TPM2 keys for LUKS auto-unlock. Read the step before running if you use full-disk encryption.
- The repo **must** live at `~/.local/share/niriland`. The deployed Niri config includes modular fragments from this path directly. If the repo lives elsewhere, the Niri config will fail to load.

## Archinstall Baseline

Recommended `archinstall` choices before running Niriland:

- **Locales**: Set keyboard layout, system language (`en_US.UTF-8`), encoding (`UTF-8`)
- **Mirrors**: Set your region (also add worldwide for safety as second mirror)
- **Disk configuration**: Use best-effort partition layout, select your disk, choose `btrfs`, enable `LUKS2` encryption, enable compression (`zstd`), choose `Snapper` for snapshots
- **Swap**: zram, `zstd` compression (should be default)
- **Bootloader**: Limine (removable: no unless you have Windows boot as well)
- **Kernels**: `linux` (should be default)
- **Hostname**: Set your hostname
- **Authentication**:
   - **Root password**: Set a root password
   - **User account**: Create your user with sudo privileges
- **Profile**: Minimal
- **Applications**:
   - **Bluetooth**: Yes
   - **Audio**: PipeWire
   - **Print service**: Yes
- **Network configuration**: NetworkManager with IWD backend
- **Additional packages**: `iwd`, `curl`, `git` (required for bootstrap)
- **Timezone**: Set your timezone
- **NTP**: Enabled (should be default)

Important: this wipes the selected disk. Review before confirming.

## Install Flow

Main entrypoint:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

Or if already cloned:

```bash
~/.local/share/niriland/install
```

The installer prompts for:

- System password for `sudo`
- LUKS password (empty input reuses system password)
- Git name/email confirmation or optional override

Steps run in order:

1. `00-setup-pacman` — pacman/paru config, Chaotic AUR
2. `05-setup-fde` — TPM2/LUKS2 full-disk encryption (skips if no TPM)
3. `10-install-drivers` — GPU driver auto-detection (AMD/Intel/NVIDIA)
4. `15-install-packages` — install from base/chaotic/AUR manifests
5. `17-setup-dms` — DMS shell and greeter setup
6. `20-deploy-configs` — copy configs to `$HOME` with backups
7. `25-setup-backgrounds` — sync wallpapers
8. `28-setup-theming` — GTK theme, icons, cursor, fonts
9. `30-setup-shell` — install zsh, set as default
10. `32-setup-keyring` — GNOME keyring + PAM integration
11. `35-setup-tools` — deploy helper scripts to `~/.local/bin/niriland`
12. `36-setup-lazyvim` — Neovim + LazyVim starter
13. `45-setup-dev` — Docker, mise, PlatformIO, cargo tools
14. `46-setup-vscodium` — VSCodium + extensions
15. `50-setup-browser` — Helium, 1Password, Widevine
16. `70-setup-desktop-entries` — desktop files and icon cache
17. `85-optimize-system` — enable fstrim/paccache timers
18. `99-post-install` — font/icon cache refresh, DMS restart, reboot reminders

Notes:

- `05-setup-fde` skips automatically if no TPM device is present.
- Several DMS/systemd user operations warn (instead of failing) when no active user session exists.
- Virtualization is intentionally opt-in via helper tools.
- After the first successful boot/login into Niri, reboot one more time. On some systems, not all user-session autostarts/services (`niriusd`, `1Password`, `JetBrains Toolbox`) come up until that second boot.

## Updating

```bash
niriland-update
```

Update behavior:

- Resolves repo from current script location, current directory, or `NIRILAND_DIR`.
- Requires a clean git worktree (fails if local changes exist).
- Runs `git pull --ff-only`.
- Runs step subsets in order: `15-*`, `20-*`, `35-*`, `70-*`, `99-*`.
- Forces `NIRILAND_CONFIG_DEPLOY_MODE=preserve` for `20-*` so existing `~/.config/*` files are not overwritten.
- Runs `cargo install-update --all` at the end to update Rust tools.

## Config Model

The deployed Niri config (`~/.config/niri/config.kdl`) layers multiple sources:

1. Niriland modular config from repo:
   `~/.local/share/niriland/configs/modules/.config/niri/config.kdl`
2. DMS-managed include files under `~/.config/niri/dms/`
3. User overrides under `~/.config/niri/override.d/`

User overrides always load last and take precedence.

## Where To Edit What

Personal overrides (safe to edit on the direct repo):

- Keybind overrides: `~/.config/niri/override.d/binds.kdl`
- Startup apps: `~/.config/niri/override.d/autostart.kdl`
- Cursor overrides: `~/.config/niri/override.d/cursor.kdl`
- DMS keybind layer: `~/.config/niri/dms/binds.kdl`

Repo-level config (only edit if you have forked the repo — modifying these on the direct repo will cause merge conflicts on update):

- Predefined keybinds: `configs/modules/.config/niri/modular/binds.kdl`
- Input settings: `configs/modules/.config/niri/modular/input.kdl`
- Layout/env/rules: `configs/modules/.config/niri/modular/*.kdl`

Validate after changes:

```bash
niri validate -c ~/.local/share/niriland/configs/modules/.config/niri/config.kdl
```

## Why We Use `nirius`

`nirius` is used for "focus-or-spawn" behavior, so common apps are focused if already open instead of launching duplicates.

It is installed in `45-setup-dev` and linked into `~/.local/bin` so Niri session keybind spawns can resolve it reliably.

Typical pattern:

```bash
nirius focus-or-spawn --app-id "obsidian" -- obsidian
```

## Helper Tools

After `35-setup-tools`, scripts are copied to `~/.local/bin/niriland` and PATH is added in `~/.zprofile` and `~/.profile`.

### Package Management

```bash
niriland-pkg install       # fuzzy search and install packages
niriland-pkg remove        # fuzzy search and remove packages
niriland-pkg upgrade       # system upgrade via paru
niriland-pkg installed     # browse installed packages
niriland-pkg clean         # clean package cache
```

Shell aliases (from `.zshrc`):

| Alias   | Command                  |
| ------- | ------------------------ |
| `npi`   | `niriland-pkg install`   |
| `npr`   | `niriland-pkg remove`    |
| `npu`   | `niriland-pkg upgrade`   |
| `npl`   | `niriland-pkg installed` |
| `clean` | `niriland-pkg clean`     |

### AI Tooling

```bash
niriland-setup-ai setup
niriland-setup-ai status
```

Installs/configures Opencode, Codex, Ollama, Docker, and OpenWebUI.

### Gaming Bundle

```bash
niriland-setup-gaming setup
niriland-setup-gaming status
```

Installs gaming packages and launchers.

### Certificates (DTU Eduroam)

```bash
niriland-setup-certificates setup
niriland-setup-certificates status
```

Installs certs and refreshes CA trust.

### Fingerprint Auth

```bash
niriland-setup-fingerprint
niriland-setup-fingerprint --remove
```

Sets up/removes fingerprint auth for sudo/polkit.

### Virtualization

```bash
niriland-vm-libvirt setup
niriland-vm-libvirt status

niriland-vm-vmware setup
niriland-vm-vmware status
```

### Browser Utilities

```bash
niriland-get-default-browser         # print app-id matcher for nirius
niriland-launch-browser [args]       # launch default browser with private-mode flag mapping
niriland-launch-webapp <url> [args]  # launch URL as browser app window
```

## Environment Variables

- `NIRILAND_REPO_URL` — bootstrap clone URL override.
- `NIRILAND_DIR` — bootstrap/update fallback repo location.
- `NIRILAND_CONFIG_DEPLOY_MODE` — config deployment mode (`overwrite` or `preserve`).
- `NIRILAND_OLLAMA_MODEL_NVIDIA` — AI setup NVIDIA model override (default `qwen2.5-coder:14b`).
- `NIRILAND_OLLAMA_MODEL_CPU` — AI setup CPU model override (default `qwen2.5-coder:3b`).

## Re-Run Strategy

Re-run full installer when needed:

```bash
./install
```

Or run a single step directly:

```bash
bash scripts/install/steps/50-setup-browser
```

If you run steps manually and they use `run_sudo`, you may need to initialize credentials first:

```bash
bash -c 'source ./scripts/install/lib/common && read_system_pass && bash ./scripts/install/steps/50-setup-browser && clean_system_pass'
```

Notes:

- Most steps are idempotent (`--needed`, compare-before-copy, check-before-append).
- `20-deploy-configs` creates backups in `~/.config/backups/niriland/<timestamp>`.
- Log out/reboot after install to apply shell/group/PAM changes.

## Troubleshooting

If commands are missing, verify foundational steps completed:

- `00-setup-pacman` for repo/bootstrap package manager setup (`paru`, Chaotic AUR, timers)
- `15-install-packages` for package manifests

For AI issues:

- Run `niriland-setup-ai status`
- Verify `ollama`, `docker.service`, and `openwebui` are active
- Verify service templates under `configs/system/etc/systemd/system/`

For ghostty theme issues:

- Ghostty will fail to find/apply themes until you add a background image to its config
- Preinstalled wallpapers are available in `~/Pictures/Wallpapers`
- To set a wallpaper: click the clock at the top → Wallpapers → press the folder icon → point to one of the wallpapers in `~/Pictures/Wallpapers`
- Once set, all wallpapers in that folder will be available next time you want to change it
