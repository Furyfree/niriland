# Niriland

Niriland is an Arch Linux post-install/bootstrap setup for a Niri + DMS desktop, packages, configs, tooling, browser setup, and optional helper tools.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

## Local Usage

```bash
git clone https://github.com/Furyfree/niriland.git
cd niriland
./install
```

## Updating Existing Installs

Use the updater tool to pull the latest repo changes and run the update subset:

```bash
scripts/tools/niriland-update
```

What it runs (in order):

- `15-*`
- `20-*`
- `70-*`
- `99-*`

During update step `20-*`, existing `~/.config/*` files are preserved (not overwritten).

`niriland-update` uses the current repo when run inside one, otherwise falls back to `NIRILAND_DIR` or `~/.local/share/niriland`.

## Requirements

- Arch Linux with `systemd`
- Internet access
- `sudo` access
- `git` installed (required by `bootstrap`)

Notes:

- The installer prompts for your sudo password and disk encryption password.
- `05-setup-fde` configures TPM unlock for existing LUKS2 root setups.

## Recommended Archinstall Baseline

Use `configs/system/archinstall/recommended.json` as a starting profile before running Niriland.

Fetch template:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/configs/system/archinstall/recommended.json -o archinstall-recommended.json
```

Edit these fields before installing:

- `disk_config.device_modifications[].device`: set your actual disk (for example `/dev/nvme0n1`)
- `hostname`: set your machine hostname
- `locale_config.kb_layout`: set your keyboard layout
- `mirror_config.mirror_regions`: set your country/region mirrors
- `timezone`: set your timezone (for example `America/New_York`)

Then run Archinstall with the edited profile:

```bash
archinstall --config archinstall-recommended.json
```

Important:

- The template uses `"wipe": true` and is destructive for the selected disk.
- Do not keep Denmark/Copenhagen values unless you are actually in that locale.

## What `install` Runs

In order:

1. `00-setup-pacman`
2. `01-setup-dms` (interactive)
3. `05-setup-fde`
4. `10-install-drivers`
5. `15-install-packages`
6. `20-deploy-configs`
7. `25-setup-backgrounds`
8. `28-setup-theming`
9. `30-setup-shell`
10. `32-setup-keyring`
11. `35-setup-tools`
12. `36-setup-lazyvim`
13. `45-setup-dev`
14. `46-setup-vscodium`
15. `50-setup-browser`
16. `70-setup-desktop-entries`
17. `85-optimize-system`
18. `99-post-install`

Virtualization is intentionally not configured by default.

Optional helper tools (run after `35-setup-tools` or after the full install):

- `niriland-vm-libvirt setup`
- `niriland-vm-vmware setup`
- `niriland-setup-gaming`
- `niriland-setup-ai`
- `niriland-setup-certificates setup`

AI model overrides (optional):

- `NIRILAND_OLLAMA_MODEL_NVIDIA` (default: `qwen2.5-coder:14b`)
- `NIRILAND_OLLAMA_MODEL_CPU` (default: `qwen2.5-coder:3b`)

## Repository Layout

- `bootstrap`: clone/update + run installer entrypoint
- `install`: main orchestrator
- `scripts/install/steps/`: numbered install steps
- `scripts/install/lib/`: shared functions
- `configs/base/`: user-level files copied to `$HOME`
- `configs/system/`: system-level files used by steps
- `packages/*.packages`: package manifests for pacman/paru
- `scripts/tools/`: utility scripts copied to `~/.local/bin/niriland`

## Re-run Behavior

Most steps are written to be safe on re-run:

- package installs use `--needed`
- file copy steps skip unchanged files
- many system edits check before appending/changing
- `46-setup-vscodium` installs only missing extensions from `packages/vscodium.extensions`; already-installed entries are skipped quietly, and only new installs/failures are logged

## What You May Still Need To Do Manually

- Log out or reboot after install (recommended).
- Validate hardware-specific behavior (GPU drivers, TPM/FDE, printer devices).
- If running headless/no session, re-run `bash scripts/install/steps/25-setup-backgrounds` later if you still need wallpaper files copied.

## Troubleshooting

- Run a single step manually:

```bash
bash scripts/install/steps/50-setup-browser
```

- If a command is missing, ensure previous foundational steps completed:
  - `00-setup-pacman` for `paru` and repo setup
  - `15-install-packages` for base/chaotic/AUR packages

- For AI setup:
  - run `niriland-setup-ai`
  - confirm Docker and Ollama services are running
  - confirm the selected OpenWebUI service template exists in `configs/system/etc/systemd/system/`

- For gaming setup:
  - run `niriland-setup-gaming`
