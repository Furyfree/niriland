# Niriland Reference

Practical reference for using and maintaining a Niriland setup.

For shortcut details, see [KEYBINDINGS.md](KEYBINDINGS.md).

## What Niriland Is

Niriland is my personal CachyOS-first desktop setup and bootstrap repo for:

- Niri compositor
- DankMaterialShell (DMS)
- Curated package manifests
- User/system config deployment
- Helper scripts for extra capabilities

It is public so other people can inspect it, learn from it, or try it on a fresh install target. It is not meant to be an installer that works across different Linux distributions or a general-purpose Linux installer.

## Scope

### Core Architecture

These parts define Niriland itself:

- Numbered install steps under `scripts/install/steps/`
- Package manifests under `packages/`
- Tracked base config deployed to `$HOME`
- Repo-hosted modular config under `configs/modules/`
- Helper tools under `scripts/tools/`

### Expected Install Assumptions

These are not optional if you want the default Niriland flow to work as designed:

- The base install choices in [../CACHYOS_INSTALL.md](../CACHYOS_INSTALL.md) have already been followed
- Repo cloned at `~/.local/share/niriland`
- Willingness to accept Niriland's default package, browser, shell, and desktop choices

### Optional Or Personal Workflows

These are included because they are useful for this setup, but they are not the core of the project:

- AI tooling setup
- Gaming setup
- Fingerprint setup
- VM helpers
- DTU certificate helper

## Warnings

- This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
- Step `05-setup-fde` adds TPM2 auto-unlock and a recovery key to an existing CachyOS LUKS setup. Read the step before running if you use full-disk encryption.
- The repo **must** live at `~/.local/share/niriland`. The installed Niri config reads shared config fragments directly from that path. Helper scripts may support other lookup paths for direct execution, but the desktop config layout depends on this exact location.

## Install Baseline

For the expected base system and installer choices before running Niriland, see [../CACHYOS_INSTALL.md](../CACHYOS_INSTALL.md).

## Install Flow

Main entrypoint:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

Or if already cloned:

```bash
~/.local/share/niriland/install
```

The installer currently asks for:

- System password for `sudo`
- LUKS password (empty input reuses system password)
- Git name/email confirmation or optional override values

This prompt order matches the current install routine. It is built for the default Niriland flow, not for the smallest possible number of prompts.

Steps run in order:

1. `00-setup-pacman` — pacman/paru config, live pacman.conf patching, Chaotic AUR
2. `05-setup-fde` — validate existing CachyOS LUKS boot config, enroll TPM2 auto-unlock, and create a recovery key (skips if no TPM)
3. `15-install-packages` — install from base/CachyOS/Chaotic/AUR manifests
4. `17-setup-dms` — DMS shell and greeter setup
5. `20-deploy-configs` — copy configs to `$HOME` with backups
6. `21-restart-portals` — restart xdg-desktop-portal services after config deploy
7. `25-setup-backgrounds` — sync wallpapers
8. `28-setup-theming` — GTK theme, icons, cursor, fonts
9. `30-setup-shell` — install zsh, set as default
10. `32-setup-keyring` — GNOME keyring + PAM integration
11. `35-setup-tools` — deploy helper scripts to `~/.local/bin/niriland`
12. `36-setup-lazyvim` — Neovim + LazyVim starter
13. `45-setup-dev` — Docker, mise, PlatformIO, cargo tools
14. `46-setup-vscodium` — VSCodium + extensions
15. `47-setup-zed` — install Zed via upstream installer
16. `50-setup-browser` — Helium, 1Password, Widevine
17. `70-setup-desktop-entries` — desktop files and icon cache
18. `85-optimize-system` — enable fstrim/paccache timers
19. `99-post-install` — font/icon cache refresh, DMS restart, reboot reminders

Notes:

- `05-setup-fde` skips automatically if no TPM device is present.
- Several DMS/systemd user operations warn (instead of failing) when no active user session exists.
- Virtualization is intentionally opt-in via helper tools instead of being part of the default install.
- After the first successful boot/login into Niri, reboot one more time. On some systems, not all user-session autostarts/services (`niriusd`, `1Password`, `JetBrains Toolbox`) come up until that second boot.

## Updating

```bash
niriland-update
```

Update behavior:

- Resolves repo from current script location, current directory, or `NIRILAND_DIR`.
- Requires a clean git worktree (fails if local changes exist).
- Runs `git pull --ff-only`.
- Runs full package upgrade via `niriland-pkg upgrade` (`paru -Syu --noconfirm`).
- Runs step subsets in order: `15-*`, `17-*`, `20-*`, `35-*`, `70-*`, `99-*`.
- Forces `NIRILAND_CONFIG_DEPLOY_MODE=preserve` for `20-*` so existing `~/.config/*` files are not overwritten.
- Runs `cargo install-update --all` at the end to update Rust tools.

The fallback lookup only exists to make script execution easier. It does not change the installed Niri config's expectation that the repo lives at `~/.local/share/niriland`.

## Config Model

The deployed Niri config (`~/.config/niri/config.kdl`) layers multiple sources:

1. Niriland modular config from repo:
   `~/.local/share/niriland/configs/modules/.config/niri/config.kdl`
2. DMS-managed include files under `~/.config/niri/dms/`
3. User overrides under `~/.config/niri/override.d/`

User overrides always load last and take precedence.

This layout is why the repo path is fixed: shared tracked config is loaded from the repo, while machine-local edits stay in override files in your home directory. The fixed path is part of how the config is designed, not a temporary limitation.

## Where To Edit What

Machine-local overrides (expected place to customize behavior without editing the tracked repo):

- Keybind overrides: `~/.config/niri/override.d/binds.kdl`
- Startup apps: `~/.config/niri/override.d/autostart.kdl`
- Cursor overrides: `~/.config/niri/override.d/cursor.kdl`
- DMS keybind layer: `~/.config/niri/dms/binds.kdl`

Repo-level config (edit these only in your own fork or local branch; changing them directly in a tracked checkout will create update/merge friction):

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

Concrete example:

```bash
nirius focus-or-spawn --app-id "obsidian" -- obsidian
```

## Helper Tools

After `35-setup-tools`, scripts are copied to `~/.local/bin/niriland` and PATH is added in `~/.zprofile` and `~/.profile`.

These tools do different jobs:

- `niriland-pkg` and `niriland-update` are core maintenance tools for the platform itself.
- AI, gaming, fingerprint, certificates, and VM helpers are optional follow-up workflows.
- Some optional helpers are only useful on certain machines or in certain environments.

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

Installs and configures Opencode, Codex, Claude Code, Ollama, Docker, and OpenWebUI. This is optional and not required for a base Niriland desktop.

### Gaming Bundle

```bash
niriland-setup-gaming setup
niriland-setup-gaming status
```

Installs CachyOS gaming packages plus Niriland gaming extras. This is optional and matches the package choices in this repo. If available, use `game-performance %command%` in Steam launch options.

### Certificates (DTU Eduroam)

```bash
niriland-setup-certificates setup
niriland-setup-certificates status
```

Installs the DTU Eduroam cert and refreshes CA trust. This helper is specific to that environment and is not required for the core project.

### Fingerprint Auth

```bash
niriland-setup-fingerprint
niriland-setup-fingerprint --remove
```

Sets up/removes fingerprint auth for sudo/polkit. This is optional machine-specific setup.

### Virtualization

```bash
niriland-vm-libvirt setup
niriland-vm-libvirt status

niriland-vm-vmware setup
niriland-vm-vmware status
```

These helpers are optional and are kept outside the default install path on purpose.

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

Re-run the full installer from the repo root when needed:

```bash
./install
```

Or run a single step directly from the repo root:

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

- `00-setup-pacman` for repo/bootstrap package manager setup (`paru`, live pacman.conf patching, Chaotic AUR, timers)
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
