# Niriland Install Scripts - Implementation Ideas

## Bootstrap & Main Installer

### `bootstrap`
- Clone repo to `~/.local/share/niriland` (or pull if exists)
- Execute `./install`

### `install`
- Welcome message
- Check if running on Arch Linux
- Interactive menu: choose which steps to run (all/select)
- Loop through `scripts/install/steps/*` in order
- Source `scripts/install/lib/common` for shared functions
- Summary at end with any failures

---

## Install Steps

### `00-setup-pacman`
- Enable Chaotic AUR (add repo to pacman.conf)
- Install paru if not present
- Configure pacman.conf:
  - Parallel downloads
  - Color output
  - ILoveCandy
  - VerbosePkgLists
  - lib32 enabled

### `05-install-drivers`
- Detect GPU (lspci | grep VGA)
- If AMD: install mesa, vulkan-radeon, lib32-mesa, lib32-vulkan-radeon
- If NVIDIA: install nvidia-dkms, nvidia-utils, lib32-nvidia-utils
- Prompt user if detection fails

### `10-install-packages`
- Read from `packages/base.txt` and install via pacman
- Read from `packages/aur.txt` and install via paru
- Skip already installed packages
- Log failed packages

### `15-setup-fde`
- Check if system is encrypted (cryptsetup status)
- Enroll key via sd-cryptenroll (TPM2 or recovery key)
- Switch from udev to systemd in mkinitcpio.conf:
  - HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
- Regenerate initramfs: limine-update

### `20-deploy-configs`
- Clone niriland repo to `~/.local/share/niriland` (or verify it exists and pull latest)
- Create backup directory: `~/.config/backups/`
- Backup existing configs to `~/.config/backups/<filename>.backup.TIMESTAMP`
- Copy configs from `~/.local/share/niriland/configs/base/` to `~/` (preserves structure: `.config/`, `.zshrc`, etc.)
- Modules in `configs/modules/` are accessed via include/source statements in base configs
- Set proper permissions (644 for config files, 755 for directories)

### `25-setup-theming`
- Install JetBrains Mono Nerd Font (AUR or manual)
- Install SF Pro (download from Apple or use AUR package)
- Install Apple Cursor
- Install Papirus Icon Theme
- Update font cache: fc-cache -fv
- Set GTK theme, dark mode, cursor and icon theme:
  - GTK theme: Adwaita-dark
  - Dark mode: true
  - Cursor: Apple
  - Icon theme: Papirus-Dark

### `30-setup-shell`
- Install zsh
- Change default shell: chsh -s /bin/zsh
- Copy/symlink zsh configs (.zshrc, .zprofile)

### `32-setup-keyring`
- Setup gnome-keyring

### `35-setup-tools`
- Create ~/.local/bin/ if not exists
- Symlink scripts/tools/* to ~/.local/bin/
- Ensure ~/.local/bin is in PATH (.zshrc or .profile)
- Make all tools executable

### `40-setup-gaming`
- Install Steam
- Install Minecraft launchers (Minecraft Launcher, Modrinth App)
- Install Faugus Launcher
- Install WoWUp, Wago (wine/bottles?)
- Enable gamemode, mangohud

### `45-setup-dev`
- Install mise (https://mise.jdx.dev)
- Install uv (Python package manager)
- Configure mise global defaults (via mise/config.toml)
- Install common runtimes via mise (node, python, etc.)

### `50-setup-browser`
- Set default browser via xdg-settings
- Symlink Widevine CDM from AUR package to Helium:
  - Source: /usr/lib/chromium/WidevineCdm
  - Target: ~/.local/share/helium/ (or wherever Helium expects it)

### `55-setup-1password`
- Trust Helium browser in 1Password:
  - Add to allowed browsers list

### `60-setup-certificates`
- Download DTU certificate (or copy from repo if included)
- Install to /etc/certs/
- Update trust store: update-ca-trust

### `65-setup-ai`
- Install Ollama (pacman or AUR)
- Install Open WebUI (docker)
- Start services: systemctl enable --now ollama
- Pull default models (llama3.2, etc.)
- Configure Open WebUI endpoint

### `70-setup-desktop-entries`
- Create custom .desktop files for webapps:
  - ChatGPT (browser --app=https://chatgpt.com)
  - Fastmail
  - Other PWAs
  - Zed launch via `WAYLAND_DISPLAY='' zeditor`
- Remove bloat desktop entries:
  - Move avahi-discover.desktop, etc. to ~/.local/share/applications/*.bak
- Update desktop database: update-desktop-database ~/.local/share/applications/

### `99-post-install`
- Enable user services (mako, etc.): systemctl --user enable mako
- Update caches:
  - fc-cache -fv (fonts)
  - gtk-update-icon-cache (icons)
  - update-desktop-database
- Set GTK theme via gsettings
- Print installation summary
- List any failed steps
- Prompt to reboot

---

## Shared Library Functions

### `scripts/install/lib/common`
- Color variables (RED, GREEN, YELLOW, BLUE, NC)
- Logging functions:
  - log_info "message"
  - log_success "message"
  - log_warning "message"
  - log_error "message"
- Confirm prompt: confirm "Question?" (returns 0/1)
- Backup function: backup_file "/path/to/file"
- Check if package installed: is_installed "package-name"
- Detect GPU: detect_gpu (returns "amd", "nvidia", "intel", or "unknown")

---

## Package Files

### `packages/base.txt`
```
# Core Niri stack
niri
xdg-desktop-portal-gnome
polkit-gnome

# Other essentials
# ... add more
```

### `packages/aur.txt`
```
limine-snapper-sync

# Other essentials
# ... add more
```

---

## Tools Scripts

For scripts that needs to be called systemwide:
- `scripts/tools/niriland-screenshot`

---

## Notes & Decisions

- **Config deployment:** Copy base configs to `~/.config/` and `~/`, then source modules from `~/.local/share/niriland/configs/modules/`
- **Config structure:** 
  - `configs/base/` → Copied to `~/` (preserves directory structure: `.config/`, `.zshrc`, etc.)
  - `configs/modules/` → Contains modular configs that are sourced/included by base configs
  - Repo is cloned to `~/.local/share/niriland/`, so modules are accessed via includes from there
- **Tools prefix:** Use `niriland-*` for all user-facing scripts
- **Package manager:** paru (faster than yay, compatible with pacman syntax, yay will be aliased to paru)
- **FDE setup:** Only run if system is already encrypted, don't force encryption
- **Interactive:** All steps should be non-interactive by default (--needed --noconfirm)
- **Idempotent:** All scripts should be safe to re-run (check before doing)
- **Error handling:** Log errors but continue with remaining steps, should stop if a critical error occurs or else skip
