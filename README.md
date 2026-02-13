# Niriland

Niriland is an Arch Linux post-install setup for a Niri + DMS desktop with curated packages, configs, and helper tooling.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

`bootstrap` clones (or updates) the repo into `~/.local/share/niriland` by default, then runs `install`.

## Local Usage

```bash
git clone https://github.com/Furyfree/niriland.git
cd niriland
./install
```

## Requirements

- Arch Linux with `systemd`
- Internet access
- `sudo` access
- `git` installed (required by `bootstrap`)

Installer prompts:

- System password for `sudo`
- LUKS password (empty input reuses system password)
- Git name/email confirmation or optional override

## Install Flow

`install` runs these steps in order:

1. `00-setup-pacman`
2. `05-setup-fde`
3. `10-install-drivers`
4. `15-install-packages`
5. `17-setup-dms`
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

Notes:

- `05-setup-fde` skips automatically if no TPM device is present.
- Several DMS/systemd user operations warn (instead of failing) when no active user session exists.
- Virtualization is intentionally opt-in via helper tools.

## Updating Existing Installs

Use:

```bash
scripts/tools/niriland-update
```

Update behavior:

- Resolves repo from current script location, current directory, or `NIRILAND_DIR`.
- Requires a clean git worktree (fails if local changes exist).
- Runs `git pull --ff-only`.
- Runs step subsets in order: `15-*`, `20-*`, `35-*`, `70-*`, `99-*`.
- Forces `NIRILAND_CONFIG_DEPLOY_MODE=preserve` for `20-*` so existing `~/.config/*` files are not overwritten.
- If `cargo-install-update` is installed, runs `cargo install-update --all` at the end.

## Optional Helper Tools

After `35-setup-tools`, scripts are copied to `~/.local/bin/niriland` and PATH is added in `~/.zprofile` and `~/.profile`.

- `niriland-update`
- `niriland-setup-ai [setup|status]`
- `niriland-setup-gaming [setup|status]`
- `niriland-setup-certificates [setup|status]`
- `niriland-setup-fingerprint [--remove]`
- `niriland-vm-libvirt [setup|status]`
- `niriland-vm-vmware [setup|status]`
- `niriland-pkg [install|remove|upgrade|installed|clean]`
- `niriland-get-default-browser`
- `niriland-launch-browser [args]`
- `niriland-launch-webapp <url> [args]`

AI model overrides:

- `NIRILAND_OLLAMA_MODEL_NVIDIA` (default `qwen2.5-coder:14b`)
- `NIRILAND_OLLAMA_MODEL_CPU` (default `qwen2.5-coder:3b`)

## Recommended Archinstall Baseline

Use `configs/system/archinstall/recommended.json` as a starting profile before running Niriland.

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/configs/system/archinstall/recommended.json -o archinstall-recommended.json
```

Edit these fields before install:

- `disk_config.device_modifications[].device` (for example `/dev/nvme0n1`)
- `hostname`
- `locale_config.kb_layout`
- `mirror_config.mirror_regions`
- `timezone`

Then:

```bash
archinstall --config archinstall-recommended.json
```

Important: the template sets `"wipe": true` for the selected disk and is destructive.

## Repository Layout

- `bootstrap`: clone/update repo and run installer entrypoint
- `install`: installer orchestrator
- `scripts/install/lib/common`: shared installer helpers
- `scripts/install/steps/`: numbered install steps
- `scripts/tools/`: helper scripts copied to `~/.local/bin/niriland`
- `configs/base/`: files deployed to `$HOME`
- `configs/modules/`: modular shared config fragments (Niri/Zsh/Ghostty)
- `configs/system/`: system-level assets used by steps/tools
- `packages/*.packages`: package manifests
- `packages/vscodium.extensions`: VSCodium extension list

## Re-run and Caveats

- Most steps are idempotent (`--needed`, compare-before-copy, check-before-append).
- `20-deploy-configs` creates backups in `~/.config/backups/niriland/<timestamp>`.
- The deployed Niri config includes `~/.local/share/niriland/configs/modules/...`; if the repo lives elsewhere, adjust `configs/base/.config/niri/config.kdl`.
- Log out/reboot after install to apply shell/group/PAM changes.

## Troubleshooting

Run one step directly:

```bash
bash scripts/install/steps/50-setup-browser
```

If commands are missing, verify foundational steps completed:

- `00-setup-pacman` for repo/bootstrap package manager setup (`paru`, Chaotic AUR, timers)
- `15-install-packages` for package manifests

For AI issues:

- run `niriland-setup-ai status`
- verify `ollama`, `docker.service`, and `openwebui` are active
- verify service templates under `configs/system/etc/systemd/system/`
