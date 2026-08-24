# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

Niriland is a personal CachyOS-first desktop bootstrap and configuration repo for
Niri. The legacy installer still deploys DankMaterialShell while the bounded
rewrite moves toward Noctalia. It is intentionally opinionated and fresh-install
oriented: installer steps can overwrite system and user configuration.

The repository is expected to live at `~/.local/share/niriland`. Some tracked
configuration references shared fragments from that exact path, so avoid changing
path assumptions unless the whole runtime model is being updated.

## Maintenance Status

- Niriland is in maintenance mode and is being superseded by Nimbus.
- Work directly on `main` unless the user explicitly requests a branch.
- Keep maintenance changes narrow; do not start new platform work here unless the
  user explicitly asks for it.

## Repository Layout

- `bootstrap` clones or updates the repo and starts the installer.
- `install` orchestrates numbered install steps.
- `niriland` is the new command; Phase 1 only enables read-only plan and status.
- `scripts/lib/` contains the new parser, plan, migration, and sudo foundations.
- `profiles/` composes purpose-based package manifests per machine.
- `tests/` contains rootless tests using temporary state and fake commands.
- `scripts/install/lib/common` contains shared installer helpers.
- `scripts/install/steps/` contains numbered install steps.
- `scripts/tools/` contains helper commands copied to `~/.local/bin/niriland`.
- `configs/base/` contains files deployed into `$HOME`.
- `configs/modules/` contains shared config fragments loaded by deployed config.
- `configs/system/` contains system-level assets used by steps and tools.
- `packages/*.packages` contains package manifests.
- `docs/` contains operational notes, migrations, roadmap, and troubleshooting.

## Editing Rules

- Keep changes scoped. This repo includes personal dotfiles and machine setup
  scripts, so do not generalize behavior beyond the stated request.
- Preserve the fresh-install model unless explicitly asked to change it.
- Do not move tracked config fragments out of `configs/modules/` without checking
  references in deployed Niri, Ghostty, or Zsh config.
- Machine-local customization should stay outside tracked config unless the user
  explicitly asks to make it the shared default.
- Treat files under `configs/base/` as deployable `$HOME` paths. A path such as
  `configs/base/.config/niri/config.kdl` deploys to `~/.config/niri/config.kdl`.
- Avoid introducing dependencies that are not listed in `packages/` or installed
  by the relevant setup step.

## Shell Script Conventions

- Use Bash for installer and helper scripts.
- Keep `set -euo pipefail` in executable scripts.
- Treat `machine.local.conf` and profile files as strict data. Never source them.
- Prefer helpers from `scripts/install/lib/common` for installer steps:
  `log`, `warn`, `die`, `require_cmd`, `ensure_sudo_session`, `run_sudo`, and
  package helpers where applicable.
- Never read or export a sudo password. Long mutating entrypoints use
  `niriland_sudo_session_start` and always stop it through a trap.
- Quote variable expansions and paths.
- Keep install steps executable and numbered by lifecycle order.
- For update-time replay behavior, check `scripts/tools/niriland-update` before
  changing installer step names or assumptions.

## Safety

- Do not run `install`, `bootstrap`, `niriland-update`, or numbered installer
  steps casually. They can install packages, change system state, deploy configs,
  and require sudo.
- Phase 1 `niriland apply`, `update`, and `postinstall` commands are reserved and
  must continue refusing mutation until their planned phases are implemented.
- Do not run package upgrade/install commands unless the user explicitly asks.
- Be careful with `20-deploy-configs`: default mode overwrites deploy targets
  after backing them up; preserve mode skips existing `.config/*` files.
- Leave unrelated user changes alone. This repo commonly contains local config
  edits and generated assets.

## Validation

For script-only changes, prefer static checks:

```bash
bash -n bootstrap install scripts/install/lib/common scripts/install/steps/* scripts/tools/*
```

If `shellcheck` is available, run it on changed shell scripts:

```bash
shellcheck -x -P SCRIPTDIR bootstrap install scripts/install/lib/common scripts/install/steps/* scripts/tools/*
```

For the rewrite foundation, also run:

```bash
bash -n niriland scripts/lib/* tests/run tests/test-*.sh
shellcheck -x -P SCRIPTDIR niriland scripts/lib/* tests/run tests/test-*.sh
tests/run
```

For package manifest changes, inspect the relevant package list and setup step
together. Do not assume a package belongs in every manifest.

For config changes, validate with the domain-specific tool when available
instead of running the full installer. Examples include checking Niri, Zsh,
Ghostty, desktop entry, or systemd syntax directly when those tools exist.

## Documentation

- Update `README.md` when install behavior, runtime model, or user-facing helper
  commands change.
- Update `docs/TROUBLESHOOTING.md` for recurring operational failures and fixes.
- Update `docs/MIGRATIONS.md` when existing installs need one-time manual or
  scripted migration steps.
- Update `docs/ROADMAP.md` only for repo-local unfinished work.
