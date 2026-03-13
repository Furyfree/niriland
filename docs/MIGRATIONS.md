# Migrations

One-time commands for existing Niriland setups when a change should be applied to older systems but does not belong in the normal update path forever.

Migration policy:

- Add new migrations at the top of this document.
- Keep entries while there is still a realistic chance that an existing machine needs the fix.
- Remove entries once all active systems are expected to be converged or the old state is no longer realistic.
- This file is for operational one-time fixes, not as a permanent changelog.

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
