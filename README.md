# Niriland

Arch Linux post-install setup for a Niri + DankMaterialShell desktop with curated packages, configs, and helper tooling.

> **Warning**
>
> - This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
> - Step `05-setup-fde` enrolls TPM2 keys for LUKS auto-unlock. Read the step before running if you use full-disk encryption.
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

## Requirements

- Arch Linux with `systemd`
- Internet access
- `sudo` access
- `git` installed

## What It Does

Installs ~100 packages (base, Chaotic AUR, AUR), deploys Niri/DMS/Ghostty/Zsh configs, sets up theming (GTK, cursors, fonts, Matugen color generation), configures dev tools (Docker, mise, Neovim/LazyVim, VSCodium), and installs optional helper scripts for AI, gaming, VMs, fingerprint auth, and more.

See [GUIDE.md](GUIDE.md) for the full reference.

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
