# Niriland

Niriland is a personal CachyOS-first workstation bootstrap and configuration
repository for Niri. It is opinionated, fresh-install oriented, and intended
for two closely aligned machines rather than as a general Linux installer.

The project is undergoing a bounded Bash maintenance rewrite. The accepted
design and phase boundaries live in [`docs/PLAN.md`](docs/PLAN.md); residual work lives in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Current status

Phase 1 provides read-only foundations:

- a gitignored machine profile selector;
- tracked desktop and laptop profiles;
- purpose-based package manifest contracts;
- stable resource IDs and plan output;
- migration discovery and immutable receipt validation;
- a sudo keepalive helper that never stores passwords;
- removal and exclusion of VSCodium's machine-local `globalStorage` database;
- removal of the machine-specific Sodium fingerprint from the Minecraft pack.

Only `niriland plan` and `niriland status` are active in the new command. The
reserved `apply`, `update`, and `postinstall` commands refuse to run until their
later phases are implemented. The existing `installer/install` and `niriland-update`
scripts remain mutating entrypoints during the transition.

## Safety

The current installer can install packages, overwrite user and system
configuration, enable services, and change groups. Read every step before using
it on an existing system.

- The repository is expected at `~/.local/share/niriland` until Phase 2 removes
  the remaining fixed-path configuration references.
- The unsafe TPM/FDE step has been removed. Reversible FDE support will
  return as an explicit post-install workflow in Phase 5.
- Sudo authentication uses `sudo -v` and a bounded keepalive. Passwords are not
  read into or exported from shell variables.
- Do not run legacy migrations casually. Phase 1 only reports them and never
  executes one.

## Machine selection

The curl bootstrap creates the ignored local selector before installation. On a
new checkout it prompts for `desktop` or `laptop`, runs the read-only plan, and
requires confirmation before starting the installer. An existing
`machine.local.conf` is preserved and validated instead of being replaced.

For a manually cloned checkout, create the selector in the repository root:

```bash
cp machine.local.example machine.local.conf
```

Select one tracked profile:

```ini
profile=desktop
```

The parser treats this file as data. Unknown keys, duplicate keys, invalid
identifiers, and shell syntax are rejected.

The current profiles compose package sets as follows:

```ini
# desktop
package_sets=base,dev,gaming,desktop

# laptop
package_sets=base,dev,gaming,laptop
```

The profile and new package files define the Phase 2 target contract. The
installer still consumes the old unqualified manifests until the package
source audit moves every package coherently. The bootstrap prints this boundary
before asking whether to continue. See
[`packages/README.md`](packages/README.md).

## Read-only command

With `machine.local.conf` present:

```bash
./bin/niriland plan
./bin/niriland plan --prune
./bin/niriland status
```

Phase 1 output deliberately labels package reconciliation, pruning, and legacy
migration conversion as deferred. Planning does not create
`~/.local/state/niriland` or change files, packages, services, or caches. The
stable output contract is documented in
[`docs/PLAN_FORMAT.md`](docs/PLAN_FORMAT.md).

## Install and update

The existing fresh-install entrypoints remain available while the reconciler is
built:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash

# or from a checkout at the required runtime path
~/.local/share/niriland/installer/install
```

The installer now asks sudo to validate its own credential cache once and keeps
that timestamp alive for the run. It no longer collects a system password or
reuses that password for disk encryption. Git name/email setup remains
interactive, as does review of PKGBUILDs before installing AUR packages.

The current maintenance helper is still:

```bash
niriland-update
```

It still upgrades packages and replays selected installer steps. Phase 4 will
replace that behavior with fetch, preview, versioned migrations, reconciliation,
and validation. It will never prune packages implicitly.

## Repository layout

- `bootstrap`: stable curl entrypoint;
- `bin/`: public commands linked into `~/.local/bin`;
- `src/niriland/`: private parser, planning, migration, state, and sudo code;
- `machine.local.example`: tracked local profile template;
- `profiles/`: tracked profile composition;
- `packages/`: current manifests plus the purpose-based target contract;
- `tests/`: rootless temporary-HOME and fake-command tests;
- `installer/install`, `installer/steps/`: transitional numbered installer;
- `configs/shared/`: shared fragments still loaded by deployed configs;
- `migrations/`: legacy migrations plus the new contract documentation;
- `configs/home`: canonical user configuration tree;
- `configs/system`: root-owned system assets;
- `docs/`: accepted plan, research, operational notes, and roadmap.

Retained optional helpers include gaming, certificates, fingerprint status,
virtualization, and WoW. The certificate workflow remains active. Unsafe
fingerprint mutation is disabled; its replacement will receive
plan/apply/revert safety work in Phase 5. VM and WoW remain unclassified until
Phase 4.

## Validation

The Phase 1 gate is:

```bash
bash -n bin/niriland src/niriland/*.sh src/niriland/commands/*.sh tests/run tests/test-*.sh
shellcheck -x -P SCRIPTDIR bin/niriland src/niriland/*.sh src/niriland/commands/*.sh tests/run tests/test-*.sh
tests/run
```

The repository-wide shell gate remains documented in `AGENTS.md`. Tests
use temporary directories and a fake sudo executable; they do not require root
or mutate the live workstation.

## Documentation

- [`docs/PLAN.md`](docs/PLAN.md): accepted rewrite scope and ordered phases;
- [`docs/RESEARCH.md`](docs/RESEARCH.md): implementation research and current evidence;
- [`docs/ROADMAP.md`](docs/ROADMAP.md): residual repo work;
- [`docs/MIGRATIONS.md`](docs/MIGRATIONS.md): legacy migration guidance;
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md): operational fixes;
- [`docs/CACHYOS_INSTALL.md`](docs/CACHYOS_INSTALL.md): expected CachyOS starting point.

## License

[GNU Affero General Public License v3](LICENSE)
