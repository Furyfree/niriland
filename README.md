# Niriland

Niriland is a personal CachyOS-first workstation bootstrap and configuration
repository for Niri. It is opinionated, fresh-install oriented, and intended
for two closely aligned machines rather than as a general Linux installer.

The project is undergoing a bounded Bash maintenance rewrite. The accepted
design and phase boundaries live in [`plan.md`](plan.md); residual work lives in
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
later phases are implemented. The existing `install` and `niriland-update`
scripts remain legacy mutating entrypoints during the transition.

## Safety

The legacy installer can install packages, overwrite user and system
configuration, enable services, and change groups. Read every step before using
it on an existing system.

- The repository is expected at `~/.local/share/niriland` until Phase 2 removes
  the remaining fixed-path configuration references.
- The unsafe legacy TPM/FDE step has been removed. Reversible FDE support will
  return as an explicit post-install workflow in Phase 5.
- Sudo authentication uses `sudo -v` and a bounded keepalive. Passwords are not
  read into or exported from shell variables.
- Do not run legacy migrations casually. Phase 1 only reports them and never
  executes one.

## Machine selection

Create the ignored local selector in the repository root:

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
legacy installer still consumes the old unqualified manifests until the package
source audit moves every package coherently. See
[`packages/README.md`](packages/README.md).

## Read-only command

With `machine.local.conf` present:

```bash
./niriland plan
./niriland plan --prune
./niriland status
```

Phase 1 output deliberately labels package reconciliation, pruning, and legacy
migration conversion as deferred. Planning does not create
`~/.local/state/niriland` or change files, packages, services, or caches. The
stable output contract is documented in
[`docs/PLAN_FORMAT.md`](docs/PLAN_FORMAT.md).

## Legacy install and update

The existing fresh-install entrypoints remain available while the reconciler is
built:

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash

# or from a checkout at the required runtime path
~/.local/share/niriland/install
```

The installer now asks sudo to validate its own credential cache once and keeps
that timestamp alive for the run. It no longer collects a system password or
reuses that password for disk encryption. Git name/email setup remains
interactive, as does review of PKGBUILDs before installing AUR packages.

The legacy maintenance helper is still:

```bash
niriland-update
```

It still upgrades packages and replays selected installer steps. Phase 4 will
replace that behavior with fetch, preview, versioned migrations, reconciliation,
and validation. It will never prune packages implicitly.

## Repository layout

- `niriland`: new read-only Phase 1 command;
- `machine.local.example`: tracked local profile template;
- `profiles/`: tracked profile composition;
- `packages/`: legacy manifests plus the purpose-based target contract;
- `scripts/lib/`: shared parser, planning, migration, state, and sudo helpers;
- `tests/`: rootless temporary-HOME and fake-command tests;
- `bootstrap`, `install`: legacy fresh-install entrypoints;
- `scripts/install/`: legacy numbered install implementation;
- `scripts/tools/`: retained runtime and post-install helpers;
- `migrations/`: legacy migrations plus the new contract documentation;
- `configs/base`, `configs/modules`: legacy layout retained until Phase 2;
- `configs/system`: root-owned system assets;
- `docs/`: operational notes, roadmap, migrations, and troubleshooting.

Retained optional helpers include gaming, certificates, fingerprint setup,
virtualization, and WoW. Certificate and fingerprint workflows are confirmed as
active and will receive plan/apply/revert safety work. VM and WoW remain
unclassified until Phase 4.

## Validation

The Phase 1 gate is:

```bash
bash -n niriland scripts/lib/* tests/run tests/test-*.sh
shellcheck -x -P SCRIPTDIR niriland scripts/lib/* tests/run tests/test-*.sh
tests/run
```

The repository-wide legacy shell gate remains documented in `AGENTS.md`. Tests
use temporary directories and a fake sudo executable; they do not require root
or mutate the live workstation.

## Documentation

- [`plan.md`](plan.md): accepted rewrite scope and ordered phases;
- [`research.md`](research.md): implementation research and current evidence;
- [`docs/ROADMAP.md`](docs/ROADMAP.md): residual repo work;
- [`docs/MIGRATIONS.md`](docs/MIGRATIONS.md): legacy migration guidance;
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md): operational fixes;
- [`CACHYOS_INSTALL.md`](CACHYOS_INSTALL.md): expected CachyOS starting point.

## License

[GNU Affero General Public License v3](LICENSE)
