# Niriland Friend Guide

This is a practical overview of how this setup is organized.
It is not a strict "run script A, then B" walkthrough.

## What Niriland Is

Niriland is an Arch Linux setup around:
- Niri compositor
- DankMaterialShell (DMS)
- Curated package manifests
- User/system config deployment
- Optional helper scripts for extra capabilities

Main installer entrypoint:

```bash
./install
```

## Optional Helpers You Can Run Any Time

These are installed to `~/.local/bin/niriland` (and added to PATH by setup).

### Update Existing Install

```bash
niriland-update
```

Notes:
- Pulls latest repo changes.
- Runs update subset (`15-*`, `20-*`, `35-*`, `70-*`, `99-*`).
- Requires a clean git working tree.

### AI Tooling

```bash
niriland-setup-ai setup
niriland-setup-ai status
```

Installs/configures Opencode, Codex, Ollama, Docker, and OpenWebUI.

### Gaming Bundle

```bash
niriland-setup-gaming setup
niriland-setup-gaming status
```

Installs gaming packages and launchers.

### Certificates (DTU Eduroam)

```bash
niriland-setup-certificates setup
niriland-setup-certificates status
```

Installs certs and refreshes CA trust.

### Fingerprint Auth

```bash
niriland-setup-fingerprint
niriland-setup-fingerprint --remove
```

Sets up/removes fingerprint auth for sudo/polkit.

### Virtualization

```bash
niriland-vm-libvirt setup
niriland-vm-libvirt status

niriland-vm-vmware setup
niriland-vm-vmware status
```

## Config Setup Model

The deployed Niri config (`~/.config/niri/config.kdl`) layers multiple sources:

1. Niriland modular config from repo:
   `~/.local/share/niriland/configs/modules/.config/niri/config.kdl`
2. DMS-managed include files under `~/.config/niri/dms/`
3. Optional user overrides (if added)

Important implication:
- Bootstrap flow (repo in `~/.local/share/niriland`) is the expected path.
- If repo lives somewhere else, adjust includes accordingly.

## Where To Edit What

- Main predefined keybinds:
  `configs/modules/.config/niri/modular/binds.kdl`
- Input settings:
  `configs/modules/.config/niri/modular/input.kdl`
- Layout/env/rules:
  `configs/modules/.config/niri/modular/*.kdl`
- Personal keybind overrides:
  `configs/base/.config/niri/override.d/binds.kdl`
- Personal startup apps:
  `configs/base/.config/niri/override.d/autostart.kdl`
- Personal cursor overrides:
  `configs/base/.config/niri/override.d/cursor.kdl`
- DMS settings keybind layer:
  `configs/base/.config/niri/dms/binds.kdl`

Validate after changes:

```bash
niri validate -c configs/modules/.config/niri/config.kdl
```

## Why We Use `nirius`

`nirius` is used for "focus-or-spawn" behavior, so common apps are focused if already open instead of launching duplicates.

It is installed in `45-setup-dev` and linked into `~/.local/bin` so Niri session keybind spawns can resolve it reliably.

Typical pattern:

```bash
nirius focus-or-spawn --app-id "obsidian" -- obsidian
```

## Re-Run Strategy

- Re-run full installer when needed:

```bash
./install
```

- Or run a single step directly:

```bash
bash scripts/install/steps/50-setup-browser
```

If you run steps manually and they use `run_sudo`, you may need to initialize credentials first:

```bash
bash -c 'source ./scripts/install/lib/common && read_system_pass && bash ./scripts/install/steps/50-setup-browser && clean_system_pass'
```

Use whichever matches the change you are making.
