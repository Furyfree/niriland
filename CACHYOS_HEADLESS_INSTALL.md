# CachyOS Install Baseline For Niriland

This file is the install baseline for a fresh Niriland target. It replaces the old `configs/system/archinstall/recommended.json` preset with a simpler source of truth.

The goal is a clean CachyOS base with full-disk encryption, Btrfs snapshots, working networking/audio/bluetooth, and no preinstalled desktop environment. Niriland installs the session stack afterwards.

## Preferred Baseline

- Fresh CachyOS install
- Minimal or headless install path
- `systemd`
- Working network access
- `sudo`
- `git`
- `curl`

## Preferred Disk Layout

- Full-disk encryption is preferred
- Use LUKS2 on the root filesystem
- Use Btrfs
- Enable Snapper snapshots
- Use `compress=zstd`

Recommended Btrfs subvolumes:

- `@` mounted at `/`
- `@home` mounted at `/home`
- `@log` mounted at `/var/log`
- `@pkg` mounted at `/var/cache/pacman/pkg`

Why:

- Niriland includes [`05-setup-fde`](/home/pby/git/niriland/scripts/install/steps/05-setup-fde), which expects an already working LUKS root and then adds TPM2 auto-unlock plus a recovery key when TPM hardware is available
- Btrfs plus Snapper fits the recovery/update workflow better than a plain ext4 layout

## Bootloader And Kernel

- Keep CachyOS defaults for drivers and system integration
- If the installer asks you to choose manually, use the default CachyOS boot path rather than adding custom boot complexity up front
- Avoid adding extra kernels during install unless you specifically need them

## Core Installer Choices

### Audio

- Use PipeWire

### Networking

- Use NetworkManager
- Use `iwd` as the Wi-Fi backend when offered

### Bluetooth

- Enable it

### Printing

- Disable it unless you actually use a printer

### Browser

- Firefox is optional
- Skip it if you already plan to use Zen, LibreWolf, Brave, or another browser

## CachyOS Package Selection

These are the convenience tools worth keeping from the installer UI.

Keep checked:

- `cachyos-settings`
- `cachyos-micro-settings`
- `cachyos-kernel-manager`
- `cachyos-packageinstaller`
- `cachyos-hello` (optional but harmless)

Optional:

- `cachyos-wallpapers`

These do not add much overhead and can make CachyOS-specific maintenance easier.

## Shell Configuration

If you manage your own shell setup, leave the CachyOS shell presets unchecked.

Leave unchecked:

- `cachyos-fish-config`
- `cachyos-zsh-config`

Reason:

- Niriland deploys its own shell setup and you likely already want your own `zsh`, Starship, and dotfiles

## Base-Devel And Common Packages

Keep these enabled.

This includes the usual system basics such as:

- network tools
- firewall
- filesystem utilities
- fonts
- audio packages
- hardware firmware
- power management

This is not harmful even if some of it is already present on the install media. Re-declaring standard tooling is better than depending on whatever a specific ISO revision happened to preinstall.

## Desktop Environments And Window Managers

Leave all of them unchecked.

Do not preinstall extra environments such as:

- LXQt
- LXDE
- UKUI
- Hyprland
- Sway
- Wayfire
- i3
- Qtile
- bspwm
- Openbox

Reason:

- Niriland installs its own Wayland session stack
- Preinstalling another DE or WM just adds packages, services, and config noise you do not need

Install your actual stack later with `pacman` if needed. For example:

```bash
sudo pacman -S niri waybar foot fuzzel
```

## Accessibility Tools

- Leave them unchecked unless you specifically need them

## Recommended Outcome

Keep:

- CachyOS base system
- Base-devel and common packages
- PipeWire
- NetworkManager with `iwd`
- Bluetooth
- Btrfs with Snapper
- LUKS2 full-disk encryption

Disable or skip:

- shell presets
- desktop environments
- window managers
- printing
- accessibility tools
- Firefox if you already use another browser

Result: a clean CachyOS base that stays close to the system defaults where that helps, while leaving the desktop/session layer for Niriland to install and manage.
