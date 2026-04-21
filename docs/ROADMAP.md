# Roadmap

This file tracks repo-local unfinished work and completed milestones.
Cross-repo design and ownership planning belongs outside this repo.
Keep entries short: problem, target state, and any important constraint.

## Active work

### Desktop and session

- [ ] Fix Vesktop screensharing on Wayland/Niri by correcting portal routing first and only adding app-specific flags if the portal-side fix is not enough.

- [ ] Add `niriland-launch-tui` and `niriland-launch-tui-presentation` as small helper scripts for normal and presentation-style TUI launches.

- [ ] Make Bluetooth reliable on the desktop machine and document any machine-specific fix that must survive updates or rebuilds.

- [ ] Decide whether a custom DMS launcher plugin is worth keeping for personal script entries, or whether desktop entries are sufficient.

- [ ] Make suspend-then-hibernate work on the current machine, including proper disk-backed swap, resume configuration, and optional DMS integration.

- [ ] Re-evaluate the default package set for terminal multiplexing and document viewing, especially `tmux` or `zellij` and a possible move from `Evince` to `zathura`.

- [ ] Trim `~/.config/environment.d/90-dms.conf` down to variables that still matter and remove overrides that are now redundant or misleading.

### Installer and update path

- [ ] Reduce `niriland-update` noise and stop replaying install-step work that is unnecessary on a normal update run.

- [ ] Simplify installer prompt flow so a normal install needs less attention and fewer unnecessary confirmations.

- [ ] Rework sudo-session handling so cached sudo credentials are reused cleanly and optional actions do not trigger avoidable prompts.

- [ ] Move the FDE auto-unlock work in `05-setup-fde` out of the default install path if it continues to behave like machine-specific follow-up instead of baseline setup.

- [ ] Add installer resumability so failed or interrupted runs can continue from a known point instead of replaying everything.

### Tooling and maintenance

- [ ] Split optional development tooling out of the default install path and keep only true baseline developer setup in the main flow.

- [ ] Add an explicit opt-in Flutter setup path with sane release resolution, browser configuration, Android prerequisites, and clear Linux versus macOS boundaries.

- [ ] Standardize tool scripts around a small shared helper library instead of duplicating logging, color, and command-check boilerplate.

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
