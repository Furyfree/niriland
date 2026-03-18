# Migrations

One-time commands for existing Niriland setups when a change should be applied to older systems but does not belong in the normal update path forever.

Migration policy:

- Add new migrations at the top of this document.
- Keep entries while there is still a realistic chance that an existing machine needs the fix.
- Remove entries once all active systems are expected to be converged or the old state is no longer realistic.
- This file is for operational one-time fixes, not as a permanent changelog.

## 2026-03 Refresh Preserved Tracked Base Configs

Who:
Existing installs whose local configs were preserved during updates and now need selected tracked files from `configs/base` replayed into `$HOME`.

Run:

```bash
bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config

bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config --list

bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config dankmaterialshell-settings

bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config app-codex icon-codex

# Example on running multiple at once
bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config zed-keymap ghostty-config
```

What it changes:

- Copies the selected tracked file or files from `~/.local/share/niriland/configs/base` into `$HOME`
- Backs up any replaced destination first under `~/.config/backups/niriland/base-config-sync/<timestamp>/`
- Supports one or many readable preset aliases in a single command, with explicit coverage for every tracked file under `configs/base`
- Can also open an interactive `fzf` picker when run without arguments
- Covers both `~/.config/*` refreshes such as `dankmaterialshell-settings` and `~/.local/share/*` refreshes such as `app-codex` and `icon-codex`
- Also supports arbitrary tracked base-config paths through `--path <relative-path>` for future one-off refreshes

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked base configs.

## 2026-03 Migrate Zsh Plugins from Zinit to Sheldon

Who:
Existing installs that already use the old Zinit-based Niriland shell config.

Run:

```bash
sudo pacman -S --needed sheldon

bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config sheldon-plugins zshrc

if pacman -Qq zinit >/dev/null 2>&1; then
  paru -Rns --noconfirm zinit
fi

rm -rf ~/.local/share/zinit
```

What it changes:

- Installs `sheldon`
- Copies the tracked Sheldon config to `~/.config/sheldon/plugins.toml`
- Refreshes `~/.zshrc` to the current tracked startup order
- Removes the `zinit` package if present
- Removes the old `~/.local/share/zinit` checkout/bootstrap directory

Fresh installs:
Not needed manually. Fresh installs get `sheldon` from `packages/cachyos.packages` and the tracked TOML through normal config deployment.

## 2026-03 Remove `faugus-launcher`

Who:
Existing installs that ran the older Niriland gaming setup and still have `faugus-launcher` installed.

Run:

```bash
if pacman -Qq faugus-launcher >/dev/null 2>&1; then
  sudo pacman -Rns faugus-launcher
fi
```

What it changes:

- Removes `faugus-launcher` from older systems that were set up before the gaming recommendation changed
- Aligns the installed launchers with the current Niriland guidance: `Lutris` for `Steam` and `Battle.net`, `Heroic` for `Epic Games`

Fresh installs:
Not needed manually. Fresh installs no longer include `faugus-launcher` in `niriland-setup-gaming`.

## 2026-03 Refresh Wallpaper Filenames

Who:
Existing installs that already synced the old wallpaper filenames into `~/Pictures/Wallpapers`.

Run:

```bash
rm -f \
  ~/Pictures/Wallpapers/daniil-silantev-VqAd3Lr3Pfc-unsplash.jpg \
  ~/Pictures/Wallpapers/nihilist-penguin-3840x2160-25229.jpg \
  ~/Pictures/Wallpapers/vadim-sherbakov-NQSWvyVRIJk-unsplash.jpg \
  ~/Pictures/Wallpapers/wallhaven-1p62vg.png

bash ~/.local/share/niriland/scripts/install/steps/30-setup-backgrounds
```

What it changes:

- Removes the old wallpaper filenames from the synced wallpapers directory
- Copies the same wallpaper assets back in under the current content-based filenames

Fresh installs:
Not needed manually. Fresh installs only see the renamed wallpaper files.

## 2026-03 Refresh Zed Keymap

Who:
Existing installs whose local `~/.config/zed/keymap.json` was preserved and therefore did not pick up the current tracked Zed shortcuts.

Run:

```bash
bash ~/.local/share/niriland/scripts/tools/niriland-sync-base-config zed-keymap
```

What it changes:

- Updates Zed to the current tracked shortcuts from Niriland
- Picks up the current `Ctrl+K Ctrl+K` keymap shortcut
- Picks up the current `Ctrl+Shift+X` extensions shortcut
- Drops old tracked Zed overrides that are no longer part of the shared keymap

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked Zed keymap.

## 2026-03 Update DankMaterialShell Suspend Settings

Who:
Existing installs whose local `~/.config/DankMaterialShell/settings.json` was preserved and therefore did not pick up the new suspend defaults.

Run:

```bash
tmp=$(mktemp)
jq '.acSuspendTimeout = 10800
  | .batterySuspendTimeout = 3600
  | .batterySuspendBehavior = 2' \
  ~/.config/DankMaterialShell/settings.json > "$tmp" &&
mv "$tmp" ~/.config/DankMaterialShell/settings.json
```

What it changes:

- Sets `acSuspendTimeout` to `10800`
- Sets `batterySuspendTimeout` to `3600`
- Sets `batterySuspendBehavior` to `2`

Fresh installs:
Not needed manually. Fresh installs already get these values from the tracked DMS settings.

## 2026-03 Refresh Deployed `niriland-update`

Who:
Existing installs whose deployed `~/.local/bin/niriland/niriland-update` still uses old step patterns and therefore does not refresh the tools directory correctly.

Run:

```bash
bash ~/.local/share/niriland/scripts/install/steps/50-setup-tools
```

What it changes:

- Replaces `~/.local/bin/niriland` with the current repo copy from `scripts/tools`
- Updates the deployed `niriland-update` script itself
- Removes stale deleted helper scripts from the deployed tools directory

Fresh installs:
Not needed manually. Fresh installs already deploy the current tool directory.

## 2026-03 Snapper Retention

Who:
Existing installs from before `07-setup-snapper` was added.

Run:

```bash
bash ~/.local/share/niriland/scripts/install/steps/07-setup-snapper
sudo systemctl start snapper-cleanup.service
sudo limine-snapper-sync
sudo snapper list | tail -n +3 | wc -l
```

What it changes:

- Sets `MAX_SNAPSHOT_ENTRIES=15` in `/etc/limine-snapper-sync.conf`
- Sets `NUMBER_MIN_AGE="86400"` in `/etc/snapper/configs/root`
- Sets `NUMBER_LIMIT="15"` in `/etc/snapper/configs/root`
- Sets `NUMBER_LIMIT_IMPORTANT="15"` in `/etc/snapper/configs/root`
- Runs snapper cleanup and then refreshes Limine snapshot entries so old boot entries are removed
- `sudo snapper list | tail -n +3 | wc -l` is a quick rough check for how many snapshots currently remain after cleanup

Fresh installs:
Not needed manually. New installs already run `07-setup-snapper`.

## 2026-03 Remove Global Mise Python

Who:
Existing installs from before the shared `mise` config stopped setting Python globally.

Run:

```bash
mise use --global --remove python
exec zsh
which python
python -V
```

What it changes:

- Removes the global `python` entry from the active `mise` state on older systems
- Stops `mise` from shadowing the system Python unexpectedly
- Avoids breakage in tools that expect the system Python path, such as `virt-manager`
- After the fix, `python -V` should resolve to the system Python (`Python 3.14.x` on the current CachyOS base)
- `uv` is the intended tool for Python project and virtual-environment workflows in this setup

Fresh installs:
Not needed manually. New installs no longer set Python globally through `mise`.
