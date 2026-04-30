# Migrations

One-time commands for existing Niriland setups when a change should be applied to older systems but does not belong in the normal update path forever.

Migration policy:

- Add new migrations at the top of this document.
- Keep entries while there is still a realistic chance that an existing machine needs the fix.
- Remove entries once all active systems are expected to be converged or the old state is no longer realistic.
- This file is for operational one-time fixes, not as a permanent changelog.

## 30. april 2026 - Run All Migrations for This Date

Who:
Existing installs that need every migration from `30. april 2026` applied in one pass.

Run:

```bash
~/.local/share/niriland/migrations/2026-04-30.sh
```

What it changes:

- Runs every migration listed for `30. april 2026`
- Applies each step idempotently so the script can be rerun on the same machine
- Verifies the important end state after the migrations complete

Fresh installs:
Not needed manually. Fresh installs should already converge through the normal install path.

## 30. april 2026 - Remove Local VM Tooling

Who:
Existing installs that previously ran `niriland-setup-vm` but should no longer keep the local virtualization stack on that machine.

Run:

```bash
for unit in \
  libvirtd.service \
  libvirtd.socket \
  virtlogd.socket \
  virtlockd.socket
do
  if systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q "^${unit}"; then
    sudo systemctl disable --now "$unit" || true
  fi
  sudo systemctl reset-failed "$unit" 2>/dev/null || true
done

if command -v virsh >/dev/null 2>&1 && sudo virsh net-info default >/dev/null 2>&1; then
  if sudo virsh net-list --name | grep -Fxq default; then
    sudo virsh net-destroy default || true
  fi

  sudo virsh net-autostart default --disable || true
fi

if getent group libvirt >/dev/null 2>&1 && id -nG "$USER" | grep -qw libvirt; then
  sudo gpasswd -d "$USER" libvirt || true
fi

remove_packages=()
for package in quickgui quickemu-git virt-manager qemu-full swtpm; do
  if pacman -Qq "$package" >/dev/null 2>&1; then
    remove_packages+=("$package")
  fi
done

if [[ ${#remove_packages[@]} -gt 0 ]]; then
  sudo pacman -Rns --noconfirm "${remove_packages[@]}"
fi

if [[ -f /etc/libvirt/network.conf ]] && grep -Fxq 'firewall_backend = "iptables"' /etc/libvirt/network.conf; then
  sudo sed -i '/^firewall_backend = "iptables"$/d' /etc/libvirt/network.conf
fi

for empty_dir in ~/.config/libvirt /var/log/libvirt /etc/libvirt; do
  if [[ -d "$empty_dir" ]]; then
    sudo rmdir "$empty_dir" 2>/dev/null || true
  fi
done
```

What it changes:

- Stops and disables libvirt-related services and sockets when present
- Stops and disables autostart for the libvirt `default` network when present
- Removes the current user from the `libvirt` group when present
- Removes the VM packages installed by `niriland-setup-vm`: `quickgui`, `quickemu-git`, `virt-manager`, `qemu-full`, and `swtpm`
- Removes the Niriland-added `firewall_backend = "iptables"` line from `/etc/libvirt/network.conf`
- Removes leftover libvirt config/log directories only when they are empty

Notes:

- This does not delete VM disk images or user VM directories such as `/var/lib/libvirt/images` or `~/VMs`.
- If those exist and should be removed, inspect and delete them manually after confirming they contain no data you need.

Fresh installs:
Not needed manually. Fresh installs do not run `niriland-setup-vm` unless explicitly requested.

## 30. april 2026 - Move Limine Save Commands to Boot Hooks

Who:
Existing installs where `limine-snapper-sync` warns that `COMMANDS_BEFORE_SAVE` and `COMMANDS_AFTER_SAVE` are deprecated.

Symptoms:

```text
DEPRECATED: COMMANDS_BEFORE_SAVE and COMMANDS_AFTER_SAVE are deprecated. Use pre/post hook scripts in /etc/boot/hooks/{pre.d,post.d}/ instead.
Remove COMMANDS_BEFORE_SAVE and COMMANDS_AFTER_SAVE from /etc/default/limine and /etc/limine-snapper-sync.conf to silence this warning.
```

Run:

```bash
sudo mkdir -p /etc/boot/hooks/pre.d /etc/boot/hooks/post.d

if sudo test -f /etc/limine-snapper-sync.conf; then
  if sudo grep -q '^MAX_SNAPSHOT_ENTRIES=' /etc/limine-snapper-sync.conf; then
    sudo sed -i 's|^MAX_SNAPSHOT_ENTRIES=.*$|MAX_SNAPSHOT_ENTRIES=15|' /etc/limine-snapper-sync.conf
  else
    printf '%s\n' 'MAX_SNAPSHOT_ENTRIES=15' | sudo tee -a /etc/limine-snapper-sync.conf >/dev/null
  fi
fi

if [[ -x /usr/bin/limine-reset-enroll ]]; then
  sudo ln -sfn /usr/bin/limine-reset-enroll /etc/boot/hooks/pre.d/10-limine-reset-enroll
fi

if [[ -x /usr/bin/limine-enroll-config ]]; then
  sudo ln -sfn /usr/bin/limine-enroll-config /etc/boot/hooks/post.d/90-limine-enroll-config
fi

for file in /etc/default/limine /etc/limine-snapper-sync.conf; do
  if sudo test -f "$file"; then
    sudo sed -i \
      -e '/^COMMANDS_BEFORE_SAVE=.*$/d' \
      -e '/^COMMANDS_AFTER_SAVE=.*$/d' \
      "$file"
  fi
done

sudo limine-snapper-sync
```

What it changes:

- Sets `MAX_SNAPSHOT_ENTRIES=15` in `/etc/limine-snapper-sync.conf`
- Ensures `limine-reset-enroll` runs from `/etc/boot/hooks/pre.d`
- Ensures `limine-enroll-config` runs from `/etc/boot/hooks/post.d`
- Removes deprecated `COMMANDS_BEFORE_SAVE` and `COMMANDS_AFTER_SAVE` settings from Limine config files
- Refreshes `/boot/limine.conf` without the deprecated-command warning

Fresh installs:
Not needed manually. Fresh installs now configure these hooks through `07-setup-snapper`.

## 30. april 2026 - Move Claude Code from `mise` and local npm to system npm for T3 Code

Who:
Existing installs where Claude Code is installed through `mise` or the old `~/.local` npm prefix, causing desktop-launched tools to resolve a different Claude binary than the interactive shell.

Symptoms:

```text
Warning: Multiple installations found
- npm-global at /home/pby/.local/share/mise/installs/node/24.15.0/bin/claude (currently running)
- native at /home/pby/.local/bin/claude
```

or `claude` resolving to a `mise` path:

```text
/home/pby/.local/share/mise/installs/node/24.15.0/bin/claude
```

Run:

```bash
# Remove Claude Code from the active Node install, which is usually mise here.
npm uninstall -g @anthropic-ai/claude-code

# Remove the older ~/.local npm-prefix install used by niriland-setup-ai.
npm uninstall -g --prefix "$HOME/.local" @anthropic-ai/claude-code

# Install Claude Code with system Node/npm. The clean PATH prevents /usr/bin/npm
# from resolving node through mise and writing back into the mise prefix.
sudo env PATH=/usr/bin:/bin /usr/bin/npm install -g @anthropic-ai/claude-code

# Refresh zsh command lookup and verify the system binary is used.
rehash
type -a claude
which claude
claude --version
```

Expected:

```text
claude is /usr/bin/claude
/usr/bin/claude
2.1.123 (Claude Code)
```

What it changes:

- Removes the old `mise` global `@anthropic-ai/claude-code` package
- Removes the older `~/.local` npm-prefix Claude Code install
- Installs `@anthropic-ai/claude-code` into the system npm prefix
- Makes GUI-launched tools such as T3 Code resolve `claude` from `/usr/bin/claude`
- Avoids Topgrade's Claude Code updater warning about multiple installations

Notes:

- Keep `/home/pby/.claude`; it is Claude Code state and configuration, not the executable.
- In T3 Code, use `claude` as the Claude binary path and fully restart the app after this migration.
- If `/usr/bin/npm config get prefix` still reports a `mise` path, verify with `env PATH=/usr/bin:/bin /usr/bin/npm config get prefix`; it should report `/usr`.

Fresh installs:
Not needed manually once Claude Code is installed through the normal system-visible package path instead of a `mise` or `~/.local` global package.

## 30. april 2026 - Remove Local OpenWebUI Docker Instance

Who:
Existing installs that previously ran `niriland-setup-ai` and now use another UI such as Page Assist locally or OpenWebUI in the homelab.

Run:

```bash
if systemctl list-unit-files --no-legend openwebui.service | grep -q '^openwebui.service'; then
  sudo systemctl disable --now openwebui.service
fi

sudo rm -f /etc/systemd/system/openwebui.service
sudo systemctl daemon-reload
sudo systemctl reset-failed openwebui.service 2>/dev/null || true

sudo systemctl start docker.service

if sudo docker ps -a --format '{{.Names}}' | grep -Fxq open-webui; then
  sudo docker rm -f open-webui
fi

for image in \
  ghcr.io/open-webui/open-webui:main \
  ghcr.io/open-webui/open-webui:cuda
do
  if sudo docker image inspect "$image" >/dev/null 2>&1; then
    sudo docker image rm "$image"
  fi
done

if sudo docker volume ls -q | grep -Fxq open-webui; then
  sudo docker volume rm open-webui
fi

systemctl is-active ollama
ollama list
```

What it changes:

- Stops and disables the local `openwebui.service` systemd unit installed by `niriland-setup-ai`
- Removes the `open-webui` Docker container if it exists
- Removes both possible OpenWebUI images used by Niriland, `main` for CPU systems and `cuda` for NVIDIA systems
- Removes the local OpenWebUI Docker data volume
- Leaves host Ollama, host Ollama models, Opencode, Codex, Claude Code, Docker, and Docker Compose installed

Notes:

- Do not remove the Docker `ollama` volume here. Older CPU OpenWebUI units mounted it, but it is separate from the host Ollama model store and should be checked manually before deletion.
- This migration intentionally removes only the local Docker UI layer. Local AI should continue through Ollama plus a non-Docker UI/client.

Fresh installs:
Not needed unless `niriland-setup-ai` has been run on that machine.

## 30. april 2026 - Refresh Codex Desktop Entry

Who:
Existing installs whose local `~/.local/share/applications/Codex.desktop` is missing or still points at an older Codex launcher target.

Run:

```bash
mkdir -p ~/.local/share/applications
cp -a ~/.local/share/niriland/configs/base/.local/share/applications/Codex.desktop ~/.local/share/applications/Codex.desktop
```

What it changes:

- Refreshes the local Codex desktop entry from the tracked Niriland config
- Points the launcher at `https://chatgpt.com/codex/cloud` through `niriland-launch-webapp`

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked desktop entry.

## 30. april 2026 - Stabilize Topgrade and Helix Updates

Who:
Existing installs that already have local Topgrade or Helix configuration and should pick up the safer Topgrade defaults plus the temporary Helix `gotmpl` grammar override.

Run:

```bash
mkdir -p ~/.config/helix
cp -a ~/.local/share/niriland/configs/base/.config/topgrade.toml ~/.config/topgrade.toml
cp -a ~/.local/share/niriland/configs/base/.config/helix/languages.toml ~/.config/helix/languages.toml

rm -rf -- ~/.config/helix/runtime/grammars/sources/gotmpl

helix --grammar fetch
helix --grammar build

topgrade --dry-run --config ~/.config/topgrade.toml --only helix --no-ask-retry
topgrade --dry-run --config ~/.config/topgrade.toml --only containers --no-ask-retry
```

What it changes:

- Adds tracked Topgrade config with `pre_sudo = true`, `ask_retry = false`, end notifications only on failure, `paru --nodevel`, Cargo git-package updates disabled, Bun self-update disabled because Bun is managed by mise, Poetry disabled because it is not part of the baseline toolset, the built-in npm step disabled because it follows the active mise Node, container image updates disabled because Docker/Podman images are managed separately, and JetBrains IDE/plugin updates disabled because JetBrains Toolbox manages those itself
- Adds Snapper snapshots before and after the full Topgrade run
- Runs `limine-snapper-sync` after the post snapshot when available
- Refreshes the DMS system updater widget as the final Topgrade post command when `dms` is available
- Adds a custom Codex CLI update command using `/usr/bin/npm`
- Keeps normal system, language-tool, editor, and package-manager updates enabled
- Adds a Helix `gotmpl` grammar override pointing at the available `ngalaiko/tree-sitter-go-template` repository
- Clears the stale cached `gotmpl` grammar source so Helix refetches from the corrected upstream

Fresh installs:
Not needed manually. Fresh installs get the tracked Topgrade and Helix config through normal config deployment.

## 30. april 2026 - Refresh Zed Feature Flags

Who:
Existing installs whose local `~/.config/zed/settings.json` was preserved and therefore did not pick up the current tracked Zed feature flags.

Run:

```bash
mkdir -p ~/.config/zed
cp -a ~/.local/share/niriland/configs/base/.config/zed/settings.json ~/.config/zed/settings.json
```

What it changes:

- Updates Zed to the current tracked settings from Niriland
- Enables `tabular-data-preview`
- Enables `notebooks`

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked Zed settings.

## 30. april 2026 - Replace Evince with Zathura

Who:
Existing installs that still have `evince` installed or whose local `~/.config/mimeapps.list` still points document MIME types at Evince.

Run:

```bash
sudo pacman -S --needed \
  zathura \
  zathura-pdf-mupdf \
  zathura-cb \
  zathura-djvu \
  tesseract-data-eng

if pacman -Qq evince >/dev/null 2>&1; then
  sudo pacman -Rns evince sushi
fi

mkdir -p ~/.config
cp -a ~/.local/share/niriland/configs/base/.config/mimeapps.list ~/.config/mimeapps.list

xdg-mime query default application/pdf
```

Expected:

```text
org.pwmt.zathura-pdf-mupdf.desktop
```

What it changes:

- Installs Zathura with MuPDF PDF support, comic archive support, DjVu support, and explicit English OCR data
- Removes `evince` from existing systems if it is still installed
- Refreshes `~/.config/mimeapps.list` so PDF/ePub/OXPS documents open with Zathura's MuPDF backend
- Sets DjVu and comic archive MIME types to the matching Zathura plugins

Notes:

- `zathura-pdf-mupdf` conflicts with `zathura-pdf-poppler`; this setup intentionally uses MuPDF.
- `tesseract-data-eng` prevents pacman from prompting for an arbitrary `tessdata` provider and avoids selecting `tesseract-data-afr` by default.
- `zathura-ps` is not installed because Niriland did not previously define a PostScript default association.

Fresh installs:
Not needed manually. Fresh installs get the Zathura package set from `packages/cachyos.packages` and the tracked MIME defaults through normal config deployment.

## 30. april 2026 - Move Codex CLI from `mise` to system npm for T3 Code

Who:
Existing installs where Codex was installed through `mise` and T3 Code cannot reliably discover or start the Codex provider from the desktop session.

Symptoms:

```text
Codex app-server provider probe failed: Invalid initialize payload: Missing key at ['codexHome'].
```

or `codex` resolving to a `mise` path:

```text
/home/pby/.local/share/mise/installs/node/24.15.0/bin/codex
```

Run:

```bash
# Remove Codex from the mise-managed Node install.
npm uninstall -g @openai/codex

# Install Codex with system Node/npm. The clean PATH prevents /usr/bin/npm
# from resolving node through mise and writing back into the mise prefix.
sudo env PATH=/usr/bin:/bin /usr/bin/npm install -g @openai/codex

# Refresh zsh command lookup and verify the system binary is used.
rehash
type -a codex
which codex
codex --version
```

Expected:

```text
codex is /usr/bin/codex
/usr/bin/codex
codex-cli 0.125.0
```

What it changes:

- Removes the old `mise` global `@openai/codex` package
- Installs `@openai/codex` into the system npm prefix
- Makes GUI-launched tools such as T3 Code resolve `codex` from `/usr/bin/codex`

Notes:

- Keep `/home/pby/.codex`; it is Codex state and configuration, not the executable.
- Use `/home/pby/.codex` as the T3 Code `CODEX_HOME path`.
- In T3 Code, use `codex` as the Codex binary path and fully restart the app after this migration.
- If `/usr/bin/npm config get prefix` still reports a `mise` path, verify with `env PATH=/usr/bin:/bin /usr/bin/npm config get prefix`; it should report `/usr`.

Fresh installs:
Not needed manually once Codex is installed through the normal system-visible package path instead of a `mise` global package.

## 7. april 2026 - Prefer `ghostty` for `xdg-terminal-exec` in `niri`

Who:
Existing installs where terminal launches started resolving to `alacritty` because `xdg-terminal-exec` had no user override configured for `niri`.

Run:

```bash
mkdir -p ~/.config
printf '%s\n' \
  '# Prefer Ghostty as the default terminal in niri sessions.' \
  'com.mitchellh.ghostty.desktop' \
  > ~/.config/niri-xdg-terminals.list
```

What it changes:

- Adds `~/.config/niri-xdg-terminals.list`
- Makes `xdg-terminal-exec` prefer `com.mitchellh.ghostty.desktop` in `niri` sessions
- Stops fallback selection from picking `Alacritty.desktop` when no terminal preference file exists

Fresh installs:
Not needed manually. Fresh installs should deploy the `niri` terminal preference through the tracked config.

## 6. april 2026 - Replace `dms-shell-bin` with `dms-shell`

Who:
Existing installs that still have `dms-shell-bin` installed.

Run:

```bash
if pacman -Qq dms-shell-bin >/dev/null 2>&1; then
  sudo pacman -Rns --noconfirm dms-shell-bin
fi

sudo pacman -S --needed dms-shell dms-shell-niri
```

What it changes:

- Removes the old `dms-shell-bin` package
- Installs `dms-shell` from the current repo package source

Fresh installs:
Not needed manually. Fresh installs now install `dms-shell` in the normal DMS setup step.

## 25. marts 2026 - Refresh Zed Settings

Who:
Existing installs whose local `~/.config/zed/settings.json` was preserved and therefore did not pick up the current tracked Zed settings.

Run:

```bash
mkdir -p ~/.config/zed
cp -a ~/.local/share/niriland/configs/base/.config/zed/settings.json ~/.config/zed/settings.json
```

What it changes:

- Updates Zed to the current tracked settings from Niriland
- Enables file icons in the Zed git panel through `"git_panel": { "file_icons": true }`

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked Zed settings.

## 18. marts 2026 - Refresh Preserved Tracked Base Configs

Who:
Existing installs whose local configs were preserved during updates and now need selected tracked files from `configs/base` replayed into `$HOME`.

Run:

```bash
BASE=~/.local/share/niriland/configs/base

# List tracked base config files if needed.
find "$BASE" \( -type f -o -type l \) | sed "s#^$BASE/##" | sort

# Copy selected files directly to their matching home paths.
mkdir -p ~/.config/DankMaterialShell
cp -a "$BASE/.config/DankMaterialShell/settings.json" ~/.config/DankMaterialShell/settings.json

mkdir -p ~/.local/share/applications ~/.local/share/icons
cp -a "$BASE/.local/share/applications/Codex.desktop" ~/.local/share/applications/Codex.desktop
cp -a "$BASE/.local/share/icons/Codex.png" ~/.local/share/icons/Codex.png

# Example on running multiple at once
mkdir -p ~/.config/zed ~/.config/ghostty
cp -a "$BASE/.config/zed/keymap.json" ~/.config/zed/keymap.json
cp -a "$BASE/.config/ghostty/config" ~/.config/ghostty/config
```

What it changes:

- Copies selected tracked files from `~/.local/share/niriland/configs/base` into the matching path under `$HOME`
- Covers both `~/.config/*` refreshes such as `.config/DankMaterialShell/settings.json` and `~/.local/share/*` refreshes such as `.local/share/applications/Codex.desktop`

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked base configs.

## 16. marts 2026 - Migrate Zsh Plugins from Zinit to Sheldon

Who:
Existing installs that already use the old Zinit-based Niriland shell config.

Run:

```bash
sudo pacman -S --needed sheldon

mkdir -p ~/.config/sheldon
cp -a ~/.local/share/niriland/configs/base/.config/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
cp -a ~/.local/share/niriland/configs/base/.zshrc ~/.zshrc

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

## 14. marts 2026 - Remove `faugus-launcher`

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

## 13. marts 2026 - Refresh Wallpaper Filenames

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

## 13. marts 2026 - Refresh Zed Keymap

Who:
Existing installs whose local `~/.config/zed/keymap.json` was preserved and therefore did not pick up the current tracked Zed shortcuts.

Run:

```bash
mkdir -p ~/.config/zed
cp -a ~/.local/share/niriland/configs/base/.config/zed/keymap.json ~/.config/zed/keymap.json
```

What it changes:

- Updates Zed to the current tracked shortcuts from Niriland
- Picks up the current `Ctrl+K Ctrl+K` keymap shortcut
- Picks up the current `Ctrl+Shift+X` extensions shortcut
- Drops old tracked Zed overrides that are no longer part of the shared keymap

Fresh installs:
Not needed manually. Fresh installs already deploy the current tracked Zed keymap.

## 13. marts 2026 - Update DankMaterialShell Suspend Settings

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

## 13. marts 2026 - Refresh Deployed `niriland-update`

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

## 13. marts 2026 - Snapper Retention

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
- Ensures Limine save commands run through `/etc/boot/hooks/{pre.d,post.d}` instead of deprecated config keys
- Sets `NUMBER_MIN_AGE="86400"` in `/etc/snapper/configs/root`
- Sets `NUMBER_LIMIT="15"` in `/etc/snapper/configs/root`
- Sets `NUMBER_LIMIT_IMPORTANT="15"` in `/etc/snapper/configs/root`
- Runs snapper cleanup and then refreshes Limine snapshot entries so old boot entries are removed
- `sudo snapper list | tail -n +3 | wc -l` is a quick rough check for how many snapshots currently remain after cleanup

Fresh installs:
Not needed manually. New installs already run `07-setup-snapper`.

## 13. marts 2026 - Remove Global Mise Python

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
