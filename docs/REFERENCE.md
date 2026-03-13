# Niriland Reference

Practical reference for using and maintaining a Niriland setup.

For shortcut details, see [KEYBINDINGS.md](KEYBINDINGS.md).
For one-time migration steps on older systems, see [MIGRATIONS.md](MIGRATIONS.md).

## What Niriland Is

Niriland is my personal CachyOS-first desktop setup and bootstrap repo for:

- Niri compositor
- DankMaterialShell (DMS)
- Curated package manifests
- User/system config deployment
- Helper scripts for extra capabilities

It is public so other people can inspect it, learn from it, or try it on a fresh install target. It expects a CachyOS base install to already be in place, and it is not meant to be an installer that works across different Linux distributions or a general-purpose Linux installer.

## System Profile

This is the practical "what you get" view of a default Niriland install.

### Core Desktop Standard

- Compositor and session shell: Niri + DankMaterialShell (DMS)
- Shell: `zsh`
- Terminal: Ghostty
- GUI file manager: Nautilus
- Terminal file manager: Yazi
- Default CLI editor: Neovim (`EDITOR=nvim`)

### Default Apps For Opening Things

These defaults come from [`configs/base/.config/mimeapps.list`](../configs/base/.config/mimeapps.list) and the deployed session environment:

- Web links and HTML: Helium
- PDF, XPS, DjVu, and comic-book archive formats: Evince
- Images: Loupe
- Video files: Showtime
- Audio files: `mpv`
- Plain text files: GNOME Text Editor
- Code, markup, config, patch, log, and similar developer-facing text files: VSCodium Wayland
- Directories: Nautilus

### Standard Tools And Their Roles

- Helium is the default browser for normal browsing and link handling.
- Zen is installed as an alternate browser and is also trusted by the bundled 1Password browser integration.
- Ghostty is the standard terminal, while `xdg-terminal-exec` is installed for launcher-friendly terminal spawning.
- Neovim is the standard terminal editor and is what `$EDITOR` points to.
- VSCodium is the standard GUI code editor and is also the default opener for many source/config file types.
- Zed is installed as a secondary GUI editor, not the main default.
- Nautilus is the standard GUI file browser; Yazi is the standard terminal file browser.
- Evince is the standard document/PDF viewer.
- Loupe is the standard image viewer.
- Showtime is the standard simple video opener.
- `mpv` is installed for media playback and is the default opener for common audio formats.
- 1Password and `1password-cli` are the standard password-management tools.
- JetBrains Toolbox is installed for JetBrains IDE management rather than pinning a single JetBrains IDE into the default install.
- Obsidian is the standard notes app in the curated package set.
- Typst in VSCodium is a good alternative writing workflow to Obsidian if you want fast live PDF preview while editing; the default VSCodium extension set includes Tinymist for that setup.
- The virtualization split is: libvirt as the long-term, consistent VM path; `quickemu-git`/Quickgui as the faster path for trying other systems or testing installs.

### Common Installed Apps

- Communication and web: Signal, Vesktop, Teams for Linux, Zoom, Helium, Zen
- Media and creative: Spotify, OBS Studio, Kdenlive, GIMP, Pinta, Draw.io Desktop
- Notes and knowledge work: Obsidian, Typst-in-VSCodium workflow
- Passwords and secrets: 1Password, `1password-cli`, Seahorse
- IDE/editor path: Neovim, VSCodium, Zed, JetBrains Toolbox

### Development And CLI Tooling

- Core environment/toolchain: `git`, `mise`, Docker, Docker Compose, PlatformIO, `gcc`, `clang`, `base-devel`
- Package helpers: `yay`, `paru`
- Terminal workflow: `zsh`, Starship, Zoxide, `fzf`, `eza`, `bat`, `ripgrep`, `fd`, `jq`, `tldr`
- Monitoring and inspection: `btop`, Fastfetch, `bandwhich`, `duf`, `dust`, `tokei`
- Git and repo helpers: GitHub CLI, LazyGit, LazyDocker
- Archive and file utilities: `zip`, `unzip`, `7zip`, `unrar`

### System Services And Machine Defaults

- Storage and mounts: `udiskie`, `gvfs`, GNOME Disk Utility
- File previews/thumbnails: Sushi, Tumbler, `ffmpegthumbnailer`, Nautilus image converter
- Security/session integration: Polkit GNOME, GNOME keyring integration, Seahorse
- Firmware/boot support: `fwupd`, `efibootmgr`, Limine, CachyOS Limine hooks
- Printing convenience: Epson ESC/P-R drivers are included in the package set
- Browser DRM support: `chromium-widevine` is included for the Helium setup
- Theming and fonts: Adwaita/GTK theme assets, Papirus icons, Bibata cursor theme, JetBrains Mono Nerd Font, Inter, Noto Emoji

### Behavior Notes

- Browser helper scripts follow the current XDG default browser, so if you change that later, `niriland-launch-browser` and `niriland-launch-webapp` follow the new default instead of hardcoding Helium.
- The fixed repo path is part of the system model: tracked shared config lives in the repo, while machine-local edits belong in home-directory override files.
- Not every low-level package is spelled out here, but this section now covers the main user-facing and system-defining parts of the current package manifests.

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

Niriland does not install CachyOS itself. It starts after that base system is already installed.

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

Step number ranges are grouped on purpose:

- `00-09` — base system preparation and disk/bootstrap follow-up
- `10-19` — core package install and desktop session setup
- `20-39` — config deployment and desktop appearance/session polish
- `40-59` — shell, keyring, helper tools, and editor bootstrap
- `60-79` — developer tools, editors, and browser setup
- `80-99` — desktop integration, maintenance, and final cleanup

Steps run in order:

1. `00-setup-pacman` — pacman/paru config, live pacman.conf patching, Chaotic AUR
2. `05-setup-fde` — validate existing CachyOS LUKS boot config, enroll TPM2 auto-unlock, and create a recovery key (skips if no TPM)
3. `07-setup-snapper` — set snapper and limine-snapper-sync retention values for the intended snapshot policy
4. `10-install-packages` — install from base/CachyOS/Chaotic/AUR manifests
5. `15-setup-dms` — DMS shell and greeter setup
6. `20-deploy-configs` — copy configs to `$HOME` with backups
7. `25-restart-portals` — restart xdg-desktop-portal services after config deploy
8. `30-setup-backgrounds` — sync wallpapers
9. `35-setup-theming` — GTK theme, icons, cursor, fonts
10. `40-setup-shell` — install zsh, set as default
11. `45-setup-keyring` — GNOME keyring + PAM integration
12. `50-setup-tools` — deploy helper scripts to `~/.local/bin/niriland`
13. `55-setup-lazyvim` — Neovim + LazyVim starter
14. `60-setup-dev` — Docker, mise, PlatformIO, cargo tools
15. `65-setup-vscodium` — VSCodium + extensions
16. `70-setup-zed` — install Zed via upstream installer
17. `75-setup-browser` — Helium, 1Password, Widevine
18. `80-setup-desktop-entries` — desktop files and icon cache
19. `85-optimize-system` — enable fstrim/paccache timers
20. `90-post-install` — font/icon cache refresh, DMS restart, reboot reminders

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
- Runs full package upgrade via `niriland-pkg upgrade` (`yay -Syu --noconfirm`).
- Runs step subsets in order: `10-*`, `15-*`, `20-*`, `50-*`, `80-*`, `90-*`.
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

It is installed in `60-setup-dev` and linked into `~/.local/bin` so Niri session keybind spawns can resolve it reliably.

Concrete example:

```bash
nirius focus-or-spawn --app-id "obsidian" -- obsidian
```

## Helper Tools

After `50-setup-tools`, scripts are copied to `~/.local/bin/niriland` and PATH is added in `~/.zprofile` and `~/.profile`.

These tools do different jobs:

- `niriland-pkg` and `niriland-update` are core maintenance tools for the platform itself.
- AI, gaming, fingerprint, certificates, and VM helpers are optional follow-up workflows.
- Some optional helpers are only useful on certain machines or in certain environments.

### Package Management

```bash
niriland-pkg install       # yay-backed combined repo + AUR picker
niriland-pkg remove        # fuzzy search and remove packages
niriland-pkg upgrade       # system upgrade via yay
niriland-pkg installed     # browse installed packages
niriland-pkg clean         # clean package cache
```

`niriland-pkg` now uses `yay` consistently for install, remove, upgrade, and cleanup flows. `install` builds one picker from pacman repo entries plus the AUR list from `yay`, so repo and AUR packages can be selected in the same TUI.

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
niriland-setup-vm
```

This helper is optional and is kept outside the default install path on purpose.

- `niriland-setup-vm` configures the supported long-term libvirt path around `qemu-full`, `virt-manager`, `swtpm`, `libvirtd`, the libvirt default network, and the expected firewall/group setup.
- It also installs `quickemu-git` and `quickgui` for fast throwaway VM/testing workflows.

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
bash scripts/install/steps/75-setup-browser
```

If you run steps manually and they use `run_sudo`, you may need to initialize credentials first:

```bash
bash -c 'source ./scripts/install/lib/common && read_system_pass && bash ./scripts/install/steps/75-setup-browser && clean_system_pass'
```

Notes:

- Most steps are idempotent (`--needed`, compare-before-copy, check-before-append).
- `20-deploy-configs` creates backups in `~/.config/backups/niriland/<timestamp>`.
- Log out/reboot after install to apply shell/group/PAM changes.

## Troubleshooting

If commands are missing, verify foundational steps completed:

- `00-setup-pacman` for repo/bootstrap package manager setup (`paru`, live pacman.conf patching, Chaotic AUR, timers)
- `10-install-packages` for package manifests

For AI issues:

- Run `niriland-setup-ai status`
- Verify `ollama`, `docker.service`, and `openwebui` are active
- Verify service templates under `configs/system/etc/systemd/system/`

For ghostty theme issues:

- Ghostty will fail to find/apply themes until you add a background image to its config
- Preinstalled wallpapers are available in `~/Pictures/Wallpapers`
- To set a wallpaper: click the clock at the top → Wallpapers → press the folder icon → point to one of the wallpapers in `~/Pictures/Wallpapers`
- Once set, all wallpapers in that folder will be available next time you want to change it
