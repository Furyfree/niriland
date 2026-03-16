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
  - [ ] Add modular `niriland-launch-tui` and `niriland-launch-tui-presentation` helper scripts.
    - [ ] `niriland-launch-tui` should just launch the requested TUI normally.
    - [ ] `niriland-launch-tui-presentation` should handle the centered floating presentation layer and call `niriland-launch-tui`.
  - [ ] Explore a custom DMS launcher plugin for personal script entries in spotlight instead of relying only on desktop entries.
    - [ ] Verify whether the right shape is a small local `launcher` plugin under `~/.config/DankMaterialShell/plugins/`.
    - [ ] Check whether script metadata and matching can be kept simple enough to feel closer to a Walker command provider.
  - [ ] Add a TUI installer flow with Gum so the bootstrap is more guided without trying to support every Linux setup.
  - [ ] Make suspend-then-hibernate work properly on the current machine instead of staying in plain suspend overnight.
    - [ ] This needs system-level changes, not just DMS. The current setup is Limine + encrypted Btrfs root + mkinitcpio with systemd hooks, and right now it only has zram swap.
    - [ ] Create a real disk-backed swapfile for hibernation. RAM is 62 GiB, so target a `70G` swapfile and keep zram enabled alongside it.
    - [ ] Get the swapfile resume offset with `btrfs inspect-internal map-swapfile -r /swap/swapfile`.
    - [ ] Add `resume=` and `resume_offset=` to the Limine kernel command line in `/etc/default/limine`.
    - [ ] Add `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` with `AllowSuspendThenHibernate=yes`, `HibernateDelaySec=2h`, and `HibernateOnACPower=yes`.
    - [ ] Add `/etc/systemd/logind.conf.d/10-lid-suspend-then-hibernate.conf` so lid close uses `suspend-then-hibernate` on battery and AC.
    - [ ] Rebuild boot artifacts with `mkinitcpio -P` and `limine-update`, then reboot.
    - [ ] Optionally set `customPowerActionSuspend` in `~/.config/DankMaterialShell/settings.json` to `systemctl suspend-then-hibernate` if the DMS suspend button should use the same action.
    - [ ] Verify with `cat /proc/cmdline`, `swapon --show`, `systemctl suspend-then-hibernate`, and `journalctl -b | rg -i 'suspend|hibernate|resume|sleep'`.
  - [ ] Split tracked user config out into a separate `dotfiles` repo and make `niriland` call it instead of owning user config deployment.
    - [ ] Move only `configs/base` and `configs/modules` into `dotfiles`; keep system assets and installer-owned files in `niriland`.
    - [ ] Make `dotfiles` the single owner of tracked user config and the only place with a deploy script.
    - [ ] Keep DMS/Niriland desktop entries and icons in `niriland` instead of moving them into `dotfiles`.
    - [ ] Use a single deploy interface in `dotfiles` with `--profile`, `--distro`, and `--mode` flags.
    - [ ] Support `--profile niriland|work`, `--distro arch|ubuntu`, and `--mode symlink|copy`.
    - [ ] Use `symlink` on personal machines to avoid drift, and `copy` on the work machine.
    - [ ] Refactor Zsh into `core`, `distro`, and `profiles`.
    - [ ] Put Pacman/Arch-specific shell config in `arch`, apt/Ubuntu-specific shell config in `ubuntu`, and DMS/Niriland-specific shell config in `niriland`.
    - [ ] Add unmanaged `~/.config/zsh/local.zsh` and always source it last on every machine.
    - [ ] Audit all tracked user config and classify each path as `symlink`, `copy`, or `unmanaged`.
    - [ ] Split ownership cleanly between `20-deploy-configs` and `80-setup-desktop-entries` as part of the migration so launcher assets have a single owner before `20-deploy-configs` is removed.
    - [ ] Move desktop-entry and icon sources into a step-owned location so `80-setup-desktop-entries` is the only owner of launcher assets.
    - [ ] Do not solve the ownership overlap by adding path-skip exceptions inside `20-deploy-configs`; fix the boundary directly.
    - [ ] Make runtime config point at a fixed `dotfiles` repo path instead of `~/.local/share/niriland/configs/modules`.
    - [ ] Add a `niriland` install/update step that clones or updates the public `dotfiles` repo and calls its deploy script with the selected flags.
    - [ ] Remove user-config deployment from `niriland` once the `dotfiles` flow is the source of truth.
  - [ ] Debloat `niriland-update` output and make the update path more efficient.
    - [ ] Remove duplicated updater output like the current self-handoff and repeated repo status messages.
    - [ ] Stop replaying install-step work that is unnecessary on a normal update run.
    - [ ] Rework step/update logging so no-change runs stay short and high-signal instead of printing huge walls of `already installed` and `unchanged` lines.
    - [ ] Keep the important package-manager and maintenance output, but trim installer noise that does not help with normal update visibility.
  - [ ] Rethink installer prompt flow so it works with less attention and fewer unnecessary prompts, instead of just moving every prompt later.
  - [ ] Rework sudo-session handling in both the installer and updater so cached sudo credentials are reused cleanly and optional or skipped functionality does not trigger avoidable prompts.
    - [ ] Consider moving the FDE auto-unlock step (`05-setup-fde`) out of the default install path and into a standalone tool script, since it is machine-specific and does not need to run on every install.
    - [x] Until sudo handling is redesigned properly, keep one-off install and migration scripts on the shared sudo-session path instead of duplicating password-prompt logic.
  - [x] Remove the current VM helper/tooling path and rebuild virtualization support from scratch around a smaller, explicitly supported stack.
    - [x] Rebuild the libvirt path around `qemu-full`, `virt-manager`, `swtpm`, `libvirtd`, libvirt group membership, default-network autostart, the required `network.conf` firewall backend, and the needed UFW route allowance for `192.168.122.0/24`, using the CachyOS reference at <https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/>.
    - [x] Re-add lightweight VM workflows around `quickemu-git` and `quickgui` after the base virtualization path is clean again.
  - [ ] Add installer resumability so a failed or interrupted run can continue from where it left off instead of replaying all steps from the beginning.
    - [ ] Support a `--from-step` flag or equivalent so the installer can skip already-completed steps.
    - [ ] Consider using marker files or exit-code tracking so the installer knows which steps finished successfully.
  - [ ] Standardize tool scripts around a shared helper library instead of each tool reinventing its own logging, color, and error-handling functions.
    - [ ] Extract a lightweight common helper for tools (separate from the full installer lib) that covers logging, color output, `die`, and `require_cmd`.
    - [ ] Migrate existing tool scripts to source the shared helper instead of inlining their own variants.
  - [x] Rework `niriland-pkg` around a coherent `yay`-based flow with a combined repo + AUR picker instead of the old broken AUR-list workaround path.
  - [x] Stop setting Python globally through `mise`, because that leaks into system-tool expectations and breaks things like `virt-manager`.
  - [x] Fix the snapper + limine-snapper-sync defaults so snapshot retention matches the intended setup.
    - [x] Set `MAX_SNAPSHOT_ENTRIES=15` in `/etc/limine-snapper-sync.conf`.
    - [x] Set `NUMBER_MIN_AGE="86400"`, `NUMBER_LIMIT="15"`, and `NUMBER_LIMIT_IMPORTANT="15"` in `/etc/snapper/configs/root`.

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
