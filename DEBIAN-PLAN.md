# Niriland: Debian Testing Support Plan

Add Debian Testing as a first-class target alongside Arch Linux. The goal is Niri + DMS on Debian Testing with Flatpak for apps not in the repos, while keeping full Arch support intact.

---

## 1. Distro Detection Helper

Add a `detect_distro()` function to `scripts/install/lib/common` that reads `/etc/os-release` and exports `NIRILAND_DISTRO` as `arch` or `debian`. Every step can then branch on this variable.

```bash
detect_distro() {
  local id
  id="$(. /etc/os-release && echo "$ID")"
  case "$id" in
    arch|endeavouros|cachyos) NIRILAND_DISTRO="arch" ;;
    debian)                   NIRILAND_DISTRO="debian" ;;
    *)                        die "Unsupported distro: $id" ;;
  esac
  export NIRILAND_DISTRO
}
```

Call it at the top of the common library so it's available everywhere.

---

## 2. Package Management Abstraction

Refactor the common library's package functions to dispatch based on `NIRILAND_DISTRO`.

### Arch (existing)

- `install_package` → `pacman -S --needed --noconfirm`
- `install_aur_package` → `paru -S --needed --noconfirm`
- `require_paru` → check for paru

### Debian (new)

- `install_package` → `apt install -y`
- `install_aur_package` → no-op / error (AUR not available)
- `install_flatpak` → new function: `flatpak install -y flathub`
- `require_paru` → skip silently on Debian

Also add:

- `is_arch()` / `is_debian()` — convenience booleans for use in conditionals
- `upgrade_all()` — `paru -Syu` on Arch, `apt update && apt full-upgrade` on Debian

---

## 3. Package Manifest Restructure

Reorganize `packages/` into distro-specific directories:

```
packages/
├── arch/
│   ├── base.packages        # (moved from packages/base.packages)
│   ├── chaotic.packages     # (moved)
│   └── aur.packages         # (moved)
├── debian/
│   ├── base.packages        # Debian package names
│   └── flatpak.packages     # Flatpak apps (Zen Browser, etc.)
├── vscodium.extensions      # shared, distro-agnostic
└── gaming/
    ├── arch.packages        # gaming packages for Arch
    └── debian.packages      # gaming packages for Debian
```

The Debian `base.packages` will need Debian-specific package names (some differ from Arch). Create this by going through the Arch `base.packages` and mapping each to its Debian equivalent.

The `flatpak.packages` for Debian would include:

- `app.zen_browser.zen` — Zen Browser
- Other apps not in Debian repos as needed

---

## 4. Step-by-Step Changes

### Step 00: `00-setup-package-manager` (renamed from `00-setup-pacman`)

**Arch path (unchanged):** configure pacman, install paru, add Chaotic AUR repo, enable timers.

**Debian path (new):**

- Verify system is on Debian Testing (check `/etc/os-release` `VERSION_CODENAME`)
- Add DankLinux OBS apt repository (niri, quickshell-git, matugen, cliphist, danksearch, dgop)
- Add DMS OBS apt repository
- Add GPG keys for both repos
- `apt update`
- Install Flatpak + add Flathub remote
- Enable `fstrim.timer`

**Prerequisite:** Debian Testing must already be installed and up to date. The installer does not handle migration from Debian Stable to Testing. Document this clearly.

### Step 05: `05-setup-fde`

**Arch path:** unchanged (mkinitcpio + systemd-cryptenroll).

**Debian path:** same systemd-cryptenroll logic, but initramfs rebuild uses:

```bash
if is_debian; then
  run_sudo update-initramfs -u
else
  run_sudo mkinitcpio -P
fi
```

Test in VM first — the crypttab format and initramfs hooks may need slight adjustments for Debian.

### Step 10: `10-install-drivers`

**Arch path:** unchanged (GPU auto-detection, pacman packages).

**Debian path:**

- AMD/Intel: mostly handled by kernel, may need `firmware-amd-graphics` or `firmware-misc-nonfree` from non-free repos
- NVIDIA: `nvidia-driver` from non-free repos (but primary target is work laptop with AMD/Intel, so low priority)

Add distro conditional for package names. For the work laptop, this step can likely be skipped or minimal.

### Step 15: `15-install-packages`

Refactor to read from `packages/arch/` or `packages/debian/` based on distro. On Debian, also install from `flatpak.packages`:

```bash
if is_arch; then
  # existing logic: base.packages, chaotic.packages, aur.packages
elif is_debian; then
  # read debian/base.packages → apt install
  # read debian/flatpak.packages → flatpak install
fi
```

### Step 17: `17-setup-dms`

Should work mostly unchanged since DMS packages come from the OBS repo added in step 00. May need minor adjustments if the DMS setup commands differ on Debian. Run `dms setup` after install.

### Step 20–28: Config deployment, portals, backgrounds, theming

**No changes expected.** These operate at the user level (`$HOME/.config/`), copying files and setting up themes. Distro-agnostic.

### Step 30: `30-setup-shell`

Minor change — `install_package zsh` will dispatch to `apt install -y zsh` on Debian automatically via the abstracted function. No other changes.

### Step 32: `32-setup-keyring`

Check if the keyring setup differs on Debian. GNOME Keyring is available on both, but package names may differ.

### Step 35: `35-setup-tools`

**No changes.** Copies scripts to `~/.local/bin/niriland`. Distro-agnostic.

### Step 36: `36-setup-lazyvim`

**No changes.** Neovim config deployment is distro-agnostic (assuming neovim is in `debian/base.packages`).

### Step 45: `45-setup-dev`

Mostly unchanged — mise handles toolchain installation regardless of distro. Docker package name may differ (`docker` on Arch vs `docker.io` on Debian). Handle in package manifest.

### Step 46: `46-setup-vscodium`

**No changes.** Extension installation via `codium --install-extension` is the same everywhere.

### Step 50: `50-setup-browser`

Major conditional split:

**Arch path:**

- Install Helium Browser + Widevine (existing)
- Set Helium as default
- Configure 1Password trusted browsers for Helium
- Webapp keybinds work via `niriland-launch-webapp` + Chromium `--app` mode

**Debian path:**

- Zen Browser installed via Flatpak (in step 15)
- Set Zen Browser as default: `xdg-settings set default-web-browser zen.desktop` (verify .desktop file name from Flatpak)
- Configure 1Password integration with Zen Browser Flatpak (needs investigation — likely Flatpak permission overrides for the 1Password socket)
- Configure 1Password trusted browsers for Zen
- **No webapp support.** Zen is Firefox-based and does not support `--app` mode. Instead, use Zen's built-in pin/superpin features for persistent access to Claude, ChatGPT, Fastmail, etc. The webapp-related keybinds (`niriland-launch-webapp`) are skipped on Debian.

### Step 70: `70-setup-desktop-entries`

May need Debian-specific .desktop files if any reference Arch-only paths or packages. Review and adjust.

### Step 85: `85-optimize-system`

**Arch path:** enable `fstrim.timer` and `paccache.timer`.

**Debian path:** enable `fstrim.timer` only (`paccache` is Arch-specific). Could add `apt-daily-cleanup.timer` or similar.

### Step 99: `99-post-install`

Review for any Arch-specific cleanup. Add Debian-specific post-install notes if needed.

---

## 5. Steps to Remove

- **VM tools** (`niriland-vm-libvirt`, `niriland-vm-vmware`) — remove entirely, never worked reliably.

---

## 6. Tool Script Updates

### `niriland-pkg`

Heavily Arch-specific (pacman, paru, fzf package browser). Options:

- Add Debian equivalents (apt + nala for nicer output, or apt + fzf)
- Or skip the interactive picker on Debian and just do `apt install` / `apt remove`

### `niriland-update`

Add distro branch:

- **Arch:** `paru -Syu` (existing)
- **Debian:** `apt update && apt full-upgrade`, `flatpak update`

### `niriland-setup-gaming`

Add Debian gaming packages:

- `steam` — available via non-free repo or Flatpak
- `prismlauncher` — in Debian repos
- `wine`, `winetricks`, `gamemode`, `mangohud` — available in Debian
- `wowup-cf-bin` — may need Flatpak or manual install on Debian
- `faugus-launcher` — check Debian availability, may need Flatpak
- `protonup-qt` — Flatpak

Create `packages/gaming/debian.packages` and `packages/gaming/debian-flatpak.packages`.

### `niriland-launch-webapp`

**Arch only.** Zen Browser (Debian default) does not support `--app` mode. On Debian, webapp keybinds are not installed and users rely on Zen's pin/superpin features instead.

On Arch, add `zen*` handling if Zen is ever used there too:

```bash
case $browser in
google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi* | helium*) ;;
zen*) browser_supports_app=false ;;  # Zen doesn't support --app
*) browser="chromium.desktop" ;;
esac
```

### `niriland-launch-browser`

Already handles `zen` in the regex for private window flags. Should work.

### `niriland-get-default-browser`

Already has `zen` in the fallback. Should work.

### Niri Keybind Modules

The webapp keybinds in `configs/modules/.config/niri/modular/binds.kdl` (Claude, ChatGPT, Fastmail, Spotify via `niriland-launch-webapp`) should be split into a separate include or conditionally skipped on Debian. The focus-or-spawn binds for native apps (1Password, Signal, etc.) remain on both distros.

---

## 7. Zen Browser + 1Password Integration

Needs investigation. Capture the exact steps from command history and test. Likely involves:

1. Flatpak permission override to expose the 1Password browser integration socket
2. Adding Zen to `/etc/1password/custom_allowed_browsers`
3. Possibly a 1Password native messaging manifest symlink into the Flatpak sandbox

Document the steps and automate in `50-setup-browser`.

---

## 8. Documentation Updates

### README.md

- Update title: remove "Arch Linux" specificity, describe multi-distro support
- Add Debian Testing to requirements section
- Update Quick Start with distro-specific prerequisites

### GUIDE.md

- Add Debian prerequisites section (must be on Testing, system up to date)
- Document Flatpak usage on Debian
- Update package management references

### POSTINSTALL.md

- Add Debian-specific post-install section
- Zen Browser extensions and preferences (parallel to Helium section)
- Note differences in default browser setup

---

## 9. Implementation Order

Suggested order to minimize risk and allow incremental testing:

1. **Distro detection** in common library + `is_arch()` / `is_debian()` helpers
2. **Package management abstraction** — refactor `install_package` etc.
3. **Package manifest split** — create `packages/arch/` and `packages/debian/` directories
4. **Step 00** — Debian repo setup (DankLinux OBS + DMS OBS + Flatpak)
5. **Step 15** — Debian package installation
6. **Step 17** — verify DMS setup works on Debian
7. **Step 50** — browser setup with Zen + 1Password
8. **Steps 20–36** — verify config deployment (should just work)
9. **Step 85 + 99** — optimize and post-install for Debian
10. **Tool scripts** — `niriland-pkg`, `niriland-update`, `niriland-setup-gaming`
11. **Documentation** updates
12. **Remove** VM tools
13. **Test** full pipeline in Debian Testing VM

---

## 10. Scope Summary

| Area | Effort | Notes |
|------|--------|-------|
| Distro detection | Trivial | ~20 lines in common lib |
| Package management abstraction | Small | Refactor existing functions |
| Package manifests | Medium | Map Arch → Debian package names |
| Step 00 (repo setup) | Medium | New Debian path, OBS repos |
| Step 05 (FDE) | Small | initramfs rebuild conditional |
| Step 10 (drivers) | Small | Low priority for AMD/Intel work laptop |
| Step 15 (packages) | Small | Branch on distro, read correct manifests |
| Step 50 (browser) | Medium | Zen+1Password investigation needed |
| Tool scripts | Medium | niriland-pkg needs most work |
| Gaming | Small-Medium | Package name mapping + Flatpak |
| Config deployment | None | Already distro-agnostic |
| Documentation | Small | README, GUIDE, POSTINSTALL updates |
| Remove VM tools | Trivial | Delete scripts |

**Overall estimate:** A focused weekend to get the core path working, another session to polish gaming and tool scripts.
