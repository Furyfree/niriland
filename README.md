# Niriland

Niriland is my personal CachyOS-first desktop setup and bootstrap repo for Niri + DankMaterialShell. It includes package lists, configs, and helper scripts. The repo is public so other people can inspect it and try it, but it is not meant to be a general Linux installer.

> **Warning**
>
> - This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
> - Step `05-setup-fde` adds TPM2 auto-unlock and a recovery key to an existing CachyOS LUKS setup. Read the step before running if you use full-disk encryption.
> - The repo **must** live at `~/.local/share/niriland`. The installed Niri config reads shared fragments directly from that path.
>
> The fixed repo path is intentional: shared tracked config stays in the repo, machine-specific overrides stay outside it, and the config layout depends on that exact path.

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

After you install CachyOS by following [CACHYOS_INSTALL.md](CACHYOS_INSTALL.md), Niriland installs the extra packages, configs, and tools used by this setup. It deploys Niri, DMS, Ghostty, and Zsh configs; sets up theming; configures dev tools like Docker, mise, Neovim/LazyVim, VSCodium, and Zed; and installs optional helper scripts for AI, gaming, VMs, fingerprint auth, and more.

See [docs/REFERENCE.md](docs/REFERENCE.md) for the full reference.
For one-time migration steps on older setups, see [docs/MIGRATIONS.md](docs/MIGRATIONS.md).
For the expected fresh-install baseline for the default Niriland flow, see [CACHYOS_INSTALL.md](CACHYOS_INSTALL.md).

Current gaming recommendation in this setup: use `Lutris` as the unified launcher for `Steam` and `Battle.net`, and use `Heroic` for `Epic Games`.

## Who It Is For

- For me and my own systems
- For people who want to inspect or experiment with my setup

## Who It Is Not For

- Not for people looking for an installer that works across many Linux distributions
- Not for existing heavily customized systems

## Why It Is Structured This Way

- Niriland keeps installer steps, package lists, tracked config, and helper tools in one repo so the full setup is easy to inspect and repeat.
- The repo path is fixed because the installed Niri config includes repo-hosted modular fragments directly from `~/.local/share/niriland`.
- Shared tracked config lives in the repo, while machine-local overrides live under `$HOME` outside the tracked tree so updates and local customization stay separate.
- The project prefers a fresh-install target because the default flow deploys its own packages and config layers instead of trying to preserve an already customized system.

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
