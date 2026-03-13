# Niriland

Niriland is my personal CachyOS-first desktop platform and bootstrap repo for Niri + DankMaterialShell, with curated packages, configs, and helper tooling. It is public for transparency and experimentation, not as a general-purpose installer.

> **Warning**
>
> - This is a **fresh-install tool**. It overwrites system and user configs. Do not run on an existing customized system without understanding what each step does.
> - Step `05-setup-fde` augments an existing CachyOS LUKS setup with TPM2 auto-unlock and a recovery key. Read the step before running if you use full-disk encryption.
> - The repo **must** live at `~/.local/share/niriland`. The installed Niri config includes repo-hosted modular fragments from this canonical location directly.
>
> The fixed repo path is intentional: tracked shared config lives in the repo, local machine-specific overrides stay outside the tracked tree, and the layered config model depends on that path coupling.

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

Installs curated base, CachyOS, Chaotic, and AUR packages; deploys Niri/DMS/Ghostty/Zsh configs; sets up theming (GTK, cursors, fonts, Matugen color generation); configures dev tools (Docker, mise, Neovim/LazyVim, VSCodium, Zed); and installs optional helper scripts for AI, gaming, VMs, fingerprint auth, and more.

See [docs/REFERENCE.md](docs/REFERENCE.md) for the full reference.
For the expected fresh-install baseline for the default Niriland flow, see [CACHYOS_INSTALL.md](CACHYOS_INSTALL.md).

## Who It Is For

- For me and my own systems
- For people who want to inspect or experiment with my setup

## Who It Is Not For

- Not for generic Linux users expecting a distro-agnostic installer
- Not for existing heavily customized systems

## Why It Is Structured This Way

- Niriland keeps installer steps, package manifests, tracked config, and helper tools in one repo so the full platform stays inspectable and repeatable.
- The repo path is fixed because the installed Niri config includes repo-hosted modular fragments directly from `~/.local/share/niriland`.
- Tracked shared config lives in the repo, while machine-local overrides live under `$HOME` outside the tracked tree so updates and local customization stay separated.
- The project prefers a fresh-install target because the default flow deploys its own packages and config layers instead of trying to preserve an already customized system.

## Roadmap

- [x] Arch-first foundation
  - [x] Start the repo with a simple Arch-oriented foundation.
  - [x] Add the first installer scaffold, numbered setup steps, shared shell helpers, and package manifest files.
  - [x] Add pacman/paru setup, base package installation, bootstrap entrypoint, and the first full-disk-encryption automation work.
  - [x] Build out the early platform flow around config deployment, shell setup, theming, keyring integration, and package-driven system setup.

- [x] Desktop platform build-out
  - [x] Add Niri + DankMaterialShell integration and turn the repo into a real desktop bootstrap instead of a loose dotfiles collection.
  - [x] Add layered tracked config plus machine-local override structure for Niri, shell, and desktop behavior.
  - [x] Add `nirius`-based focus-or-spawn behavior and the helper scripts that support browser and webapp launching.
  - [x] Tighten desktop polish with theming, wallpapers, portal restarts, desktop entries, power profile setup, and post-install session fixes.
  - [x] Continue refining default packages and desktop behavior as the platform stabilized, including DMS settings, browser handling, editor setup, and base package changes.

- [x] Maintenance and optional tooling
  - [x] Add updater and maintenance flows so package upgrades and selected install-step replays can be run after the initial install.
  - [x] Add `niriland-pkg`, keybinding reference docs, the guide, and the current project framing/documentation pass.
  - [x] Add editor and developer setup for Neovim/LazyVim, VSCodium, Zed, Docker, mise, PlatformIO, cargo tools, and related desktop integration.
  - [x] Add browser and password-manager integration around Helium, Zen, Widevine, and 1Password.
  - [x] Move gaming, AI, certificates, fingerprint auth, and virtualization into helper tools instead of forcing them into the default install path.

- [x] CachyOS-first pivot
  - [x] Pivot the platform from Arch-first assumptions to a CachyOS-first base.
  - [x] Replace the old install story with a CachyOS baseline and then simplify it further into the current CachyOS install guide.
  - [x] Fold CachyOS-specific system behavior into the installer, including package/tweak normalization and FDE/Limine follow-up work.

- [x] Documentation cleanup
  - [x] Clean up the public documentation surface by clarifying project scope, reorganizing docs out of the root, renaming the CachyOS install doc, and rechecking the keybinding reference against the current config.

- [ ] Next work
  - [ ] Add a TUI installer flow with Gum so the bootstrap experience is more guided without turning the project into a universal installer.
  - [ ] Rethink installer prompt flow so it balances low-attention installation with fewer unnecessary prompts, instead of just moving every prompt later.
  - [ ] Rework sudo-session handling in both the installer and updater so cached sudo credentials are reused cleanly and optional or skipped functionality does not trigger avoidable prompts.
  - [ ] Audit helper tools and remove, merge, or rewrite the ones that are untested, unused, or no longer justified in the current platform scope, especially the VM-related scripts.
  - [ ] Rework `niriland-pkg` to be faster, more robust, and less dependent on the current AUR list workaround that still exists because the piped package list has shown bogus entries and broken names in `fzf`.
  - [ ] Keep reviewing hidden assumptions in installer steps and helper scripts, then either remove them or document them explicitly.
  - [ ] Keep polishing the current CachyOS-first platform without broadening it into a universal installer.

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
