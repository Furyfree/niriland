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

For known issues and operational fixes, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).
For one-time migration steps on older setups, see [docs/MIGRATIONS.md](docs/MIGRATIONS.md).
For repo-local unfinished work, see [docs/ROADMAP.md](docs/ROADMAP.md).
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

## Runtime Model

- The repo must live at `~/.local/share/niriland`.
- Shared tracked config is loaded from the repo.
- Machine-local changes belong outside the tracked tree.
- The deployed Niri config layers repo config first, DMS-managed includes second, and user overrides last.

Use these override locations for local customization:

- `~/.config/niri/override.d/binds.kdl`
- `~/.config/niri/override.d/autostart.kdl`
- `~/.config/niri/override.d/cursor.kdl`
- `~/.config/niri/dms/binds.kdl`

Terminal preference and file-type defaults are separate:

- terminal launcher preference: `~/.config/niri-xdg-terminals.list`
- file associations and default editor: `~/.config/mimeapps.list`

## Install And Update

Install entrypoints:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
~/.local/share/niriland/install
```

The installer currently asks for:

- system password for `sudo`
- LUKS password, with empty input reusing the system password
- git name/email confirmation or override values

The install flow is grouped by purpose:

- `00-09`: base system preparation
- `10-19`: package install and desktop setup
- `20-39`: config deploy and desktop polish
- `40-59`: shell, keyring, helper tools, editor bootstrap
- `60-79`: developer tools, editors, browser setup
- `80-99`: desktop integration and cleanup

For normal maintenance:

```bash
niriland-update
```

Current update behavior:

- requires a clean git worktree
- runs `git pull --ff-only`
- runs a full package upgrade through `niriland-pkg upgrade`
- replays selected install steps
- preserves existing local config during `20-deploy-configs`

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

## Helper Tools

After `50-setup-tools`, helper scripts are copied to `~/.local/bin/niriland`.

Main tools:

- `niriland-pkg` — package install, remove, upgrade, and cleanup helper
- `niriland-update` — repo update plus selected maintenance replay
- `niriland-sync-base-config` — replay selected tracked files into `$HOME`

Optional follow-up helpers:

- AI
- gaming
- WoW
- Helix
- certificates
- fingerprint auth
- virtualization

## License

[GNU Affero General Public License v3](LICENSE)
