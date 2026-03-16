# Roadmap

This file tracks active work and completed milestones. Major areas use headers,
while actionable items stay as checkboxes so larger efforts can later link out
to deeper planning documents without turning the main roadmap into one long
checklist.

## Active work

### Desktop and session

#### Vesktop screensharing

- [ ] Fix Vesktop screensharing on Wayland/Niri.
  - [ ] Stop forcing `xdg-desktop-portal` to `default=gtk` in `~/.config/xdg-desktop-portal/portals.conf`, because the GTK portal does not provide the `ScreenCast` interface.
  - [ ] Restore Niri's intended portal preference order so screencast requests go to a backend that supports `ScreenCast` and `RemoteDesktop`, matching `/usr/share/xdg-desktop-portal/niri-portals.conf`.
  - [ ] Restart the user portal services and Vesktop after the portal routing change so the new backend selection is actually picked up.
  - [ ] Re-test Vesktop screensharing after the portal fix before changing any app flags.
  - [ ] If screensharing still fails after the portal fix, add a `~/.config/vesktop-flags.conf` fallback with the needed Wayland/PipeWire Electron flags and test again.

#### TUI launcher helpers

- [ ] Add modular `niriland-launch-tui` and `niriland-launch-tui-presentation` helper scripts.
  - [ ] `niriland-launch-tui` should just launch the requested TUI normally.
  - [ ] `niriland-launch-tui-presentation` should handle the centered floating presentation layer and call `niriland-launch-tui`.

#### DMS launcher plugin exploration

- [ ] Explore a custom DMS launcher plugin for personal script entries in spotlight instead of relying only on desktop entries.
  - [ ] Verify whether the right shape is a small local `launcher` plugin under `~/.config/DankMaterialShell/plugins/`.
  - [ ] Check whether script metadata and matching can be kept simple enough to feel closer to a Walker command provider.

#### TUI installer flow

- [ ] Add a TUI installer flow with Gum so the bootstrap is more guided without trying to support every Linux setup.

#### Suspend-then-hibernate

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

#### Package and default-app adjustments

- [ ] Re-evaluate the default package set for terminal multiplexing and document viewing.
  - [ ] Consider adding a terminal multiplexer to the default package set, likely `tmux` or possibly `zellij`.
  - [ ] If the choice is `tmux`, keep in mind that it is common on servers, is often already preinstalled, and supports Matugen theming.
  - [ ] Consider adding `zathura` to the default package set.
  - [ ] If `zathura` becomes the default document/PDF viewer, replace the current Evince default for that purpose.
  - [ ] Update the shipped XDG MIME defaults so PDF/document associations point at `zathura` instead of the current viewer when that switch happens.

### Dotfiles integration

- [ ] Move tracked user config ownership to `dotfiles`.
  - [ ] Keep the detailed redesign, theming, and migration plan in `dotfiles/docs/redesign-plan.md`.
  - [ ] Keep tracked user theming and browser config ownership in `dotfiles`.
  - [ ] Clone or update `dotfiles` during Niriland install/update.
  - [ ] Call `scripts/deploy-linux --profile niriland --distro arch --mode <symlink|copy>` from Niriland, defaulting to `symlink` but allowing `copy` as an explicit override when needed.
  - [ ] Document the default `symlink` mode and the explicit `copy` override clearly in the Niriland README.
  - [ ] Audit other user-facing deploy flags and document them clearly in the Niriland README as well.
  - [ ] Remove tracked user-config deployment from `20-deploy-configs`.
  - [ ] Keep `80-setup-desktop-entries` as the sole owner of launcher assets.
  - [ ] Update Niriland docs and runtime references once `dotfiles` becomes the source of truth.

### Installer and update path

#### Update output and efficiency

- [ ] Debloat `niriland-update` output and make the update path more efficient.
  - [ ] Remove duplicated updater output like the current self-handoff and repeated repo status messages.
  - [ ] Stop replaying install-step work that is unnecessary on a normal update run.
  - [ ] Rework step/update logging so no-change runs stay short and high-signal instead of printing huge walls of `already installed` and `unchanged` lines.
  - [ ] Keep the important package-manager and maintenance output, but trim installer noise that does not help with normal update visibility.

#### Installer prompt flow

- [ ] Rethink installer prompt flow so it works with less attention and fewer unnecessary prompts, instead of just moving every prompt later.

#### Sudo-session handling

- [ ] Rework sudo-session handling in both the installer and updater so cached sudo credentials are reused cleanly and optional or skipped functionality does not trigger avoidable prompts.
  - [ ] Consider moving the FDE auto-unlock step (`05-setup-fde`) out of the default install path and into a standalone tool script, since it is machine-specific and does not need to run on every install.
  - [x] Until sudo handling is redesigned properly, keep one-off install and migration scripts on the shared sudo-session path instead of duplicating password-prompt logic.

#### Installer resumability

- [ ] Add installer resumability so a failed or interrupted run can continue from where it left off instead of replaying all steps from the beginning.
  - [ ] Support a `--from-step` flag or equivalent so the installer can skip already-completed steps.
  - [ ] Consider using marker files or exit-code tracking so the installer knows which steps finished successfully.

### Tooling and maintenance

#### Shared tool helper library

- [ ] Standardize tool scripts around a shared helper library instead of each tool reinventing its own logging, color, and error-handling functions.
  - [ ] Extract a lightweight common helper for tools (separate from the full installer lib) that covers logging, color output, `die`, and `require_cmd`.
  - [ ] Migrate existing tool scripts to source the shared helper instead of inlining their own variants.

## Recently completed work

### Platform refinements

#### Virtualization stack rebuild

- [x] Remove the current VM helper/tooling path and rebuild virtualization support from scratch around a smaller, explicitly supported stack.
  - [x] Rebuild the libvirt path around `qemu-full`, `virt-manager`, `swtpm`, `libvirtd`, libvirt group membership, default-network autostart, the required `network.conf` firewall backend, and the needed UFW route allowance for `192.168.122.0/24`, using the CachyOS reference at <https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/>.
  - [x] Re-add lightweight VM workflows around `quickemu-git` and `quickgui` after the base virtualization path is clean again.

#### Package workflow rework

- [x] Rework `niriland-pkg` around a coherent `yay`-based flow with a combined repo + AUR picker instead of the old broken AUR-list workaround path.

#### Global Python removal

- [x] Stop setting Python globally through `mise`, because that leaks into system-tool expectations and breaks things like `virt-manager`.

#### Snapper retention defaults

- [x] Fix the snapper + limine-snapper-sync defaults so snapshot retention matches the intended setup.
  - [x] Set `MAX_SNAPSHOT_ENTRIES=15` in `/etc/limine-snapper-sync.conf`.
  - [x] Set `NUMBER_MIN_AGE="86400"`, `NUMBER_LIMIT="15"`, and `NUMBER_LIMIT_IMPORTANT="15"` in `/etc/snapper/configs/root`.

## Earlier completed milestones

### Arch-first foundation

#### Foundation build-out

- [x] Start the repo with a simple Arch-oriented foundation.
- [x] Add the first installer scaffold, numbered setup steps, shared shell helpers, and package manifest files.
- [x] Add pacman/paru setup, base package installation, bootstrap entrypoint, and the first full-disk-encryption automation work.
- [x] Build out the early platform flow around config deployment, shell setup, theming, keyring integration, and package-driven system setup.

### Desktop platform build-out

#### Desktop platform build-out

- [x] Add Niri + DankMaterialShell integration and turn the repo into a real desktop bootstrap instead of a loose dotfiles collection.
- [x] Add layered tracked config plus machine-local override structure for Niri, shell, and desktop behavior.
- [x] Add `nirius`-based focus-or-spawn behavior and the helper scripts that support browser and webapp launching.
- [x] Tighten desktop polish with theming, wallpapers, portal restarts, desktop entries, power profile setup, and post-install session fixes.
- [x] Continue refining default packages and desktop behavior as the platform stabilized, including DMS settings, browser handling, editor setup, and base package changes.

### Maintenance and optional tooling

#### Maintenance and optional tooling

- [x] Add updater and maintenance flows so package upgrades and selected install-step replays can be run after the initial install.
- [x] Add `niriland-pkg`, keybinding reference docs, the guide, and the current project framing/documentation pass.
- [x] Add editor and developer setup for Neovim/LazyVim, VSCodium, Zed, Docker, mise, PlatformIO, cargo tools, and related desktop integration.
- [x] Add browser and password-manager integration around Helium, Zen, Widevine, and 1Password.
- [x] Move gaming, AI, certificates, fingerprint auth, and virtualization into helper tools instead of forcing them into the default install path.

### CachyOS-first pivot

#### CachyOS-first pivot

- [x] Pivot the platform from Arch-first assumptions to a CachyOS-first base.
- [x] Replace the old install story with a CachyOS baseline and then simplify it further into the current CachyOS install guide.
- [x] Fold CachyOS-specific system behavior into the installer, including package/tweak normalization and FDE/Limine follow-up work.

### Documentation cleanup

#### Documentation cleanup

- [x] Clean up the public documentation surface by clarifying project scope, reorganizing docs out of the root, renaming the CachyOS install doc, and rechecking the keybinding reference against the current config.
