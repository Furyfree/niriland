# Niriland

CachyOS post-install setup for a Niri + DankMaterialShell desktop with curated packages, configs, and helper tooling.

> **Warning**
>
> - This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
> - Step `05-setup-fde` augments an existing CachyOS LUKS setup with TPM2 auto-unlock and a recovery key. Read the step before running if you use full-disk encryption.
> - The repo **must** live at `~/.local/share/niriland`. Niri configs reference this path directly.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

Or clone locally:

```bash
git clone https://github.com/Furyfree/niriland.git ~/.local/share/niriland
~/.local/share/niriland/install
```

Post-install note: after your first successful login into Niri, reboot one more time. Some systems do not start all user-session autostarts/services (`niriusd`, `1Password`, `JetBrains Toolbox`) until the second boot.

## Requirements

- CachyOS with `systemd`
- Internet access
- `sudo` access
- `git` installed

## What It Does

Installs curated base, CachyOS, Chaotic, and AUR packages; applies CachyOS tweaks; deploys Niri/DMS/Ghostty/Zsh configs; sets up theming (GTK, cursors, fonts, Matugen color generation); configures dev tools (Docker, mise, Neovim/LazyVim, VSCodium, Zed); and installs optional helper scripts for AI, gaming, VMs, fingerprint auth, and more.

See [GUIDE.md](GUIDE.md) for the full reference.
For the recommended fresh-install baseline, see [CACHYOS_HEADLESS_INSTALL.md](CACHYOS_HEADLESS_INSTALL.md).

## Repository Layout

- `bootstrap` — clone/update repo and run installer
- `install` — installer orchestrator
- `scripts/install/lib/common` — shared installer helpers
- `scripts/install/steps/` — numbered install steps
- `scripts/tools/` — helper scripts copied to `~/.local/bin/niriland`
- `configs/base/` — files deployed to `$HOME`
- `configs/modules/` — modular shared config fragments (Niri/Zsh/Ghostty)
- `configs/system/` — system-level assets used by steps/tools
- `packages/*.packages` — package manifests
- `packages/vscodium.extensions` — VSCodium extension list

## License

[GNU Affero General Public License v3](LICENSE)
