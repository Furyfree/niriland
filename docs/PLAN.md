# Niriland maintenance rewrite plan

## Purpose

Niriland will be the small, practical Bash implementation that keeps two
CachyOS machines in the same desired state without first requiring Nimbus or
the separate dotfiles project.

The result should provide:

- the same baseline setup on the desktop and laptop;
- a small number of explicit machine differences;
- Niri with Noctalia v5 and Noctalia Greeter;
- a plan/apply model that reports drift before correcting it;
- symlinks for all managed user configuration;
- root-owned copies for system configuration outside the user's home;
- safe, manual post-install actions for stateful system changes;
- fewer scripts with clear ownership;
- no passwords, runtime databases, or machine state in Git.

This file owns the rewrite scope, phase order, and acceptance criteria.
`docs/ROADMAP.md` is an input to this plan. Phase 1 will reduce that roadmap to
work that genuinely remains outside this plan.

## Accepted decisions

- Stay on CachyOS for now. A move to Arch or Fedora is a later, separate
  decision.
- Stay on Niri. Hyprland is not part of this rewrite.
- Replace DankMaterialShell with Noctalia v5.
- Use Noctalia Greeter for login.
- Both machines may have Steam and Minecraft through the shared gaming set.
- The desktop gets a tracked, explicit list for the additional full gaming
  stack. There will not be a separate Minecraft profile.
- A gitignored local file selects the machine profile. Tracked profile files
  compose purpose-based package manifests and define reproducible differences.
- Both machines are already on the same baseline. Remove the root `cleanup`
  script, `migrations/2026-08-19-common-baseline.sh`, and their documentation
  references.
- FDE/TPM auto-unlock must not run during normal installation. It becomes an
  explicit and reversible post-install workflow. Remove the unsafe legacy step
  instead of leaving it available for manual execution.
- Multiplexing and TUI launchers move to Herdr.
- Bluetooth works on both machines and does not need a Niriland fix.
- Vesktop screen sharing works on this machine. Preserve the working settings
  instead of inventing a new setup.
- Versioned migrations run as part of `niriland update` so existing machines
  can move safely between desired-state revisions.
- Long install and post-install flows invalidate cached sudo credentials with
  `sudo -k` when they finish. Short package-only flows may retain the normal
  sudo timeout.
- Certificate and fingerprint setup remain supported post-install workflows.
- Nimbus, the Go implementation, and the separate dotfiles project are not
  prerequisites for this work.

## Out of scope

- Fedora, an Arch migration, or Hyprland.
- Automatic disk partitioning or automatic TPM-unlock activation.
- Automatically deleting undeclared packages during a normal update.
- Synchronizing credentials, cookies, tokens, caches, or application databases.
- Multiplexing, TUI presentation helpers, or other Herdr functionality.
- Flutter, Helium, Helix, or local Ollama/OpenWebUI setup.
- A generic configuration engine or a new implementation language.

## Desired repository model

`configs/home` is the canonical user tree. For example,
`configs/home/.config/niri/config.kdl` owns `~/.config/niri/config.kdl`.
System files remain under `configs/system/` because `/etc` must never contain
symlinks into a user-owned Git repository. Shared fragments that are still loaded
at runtime are isolated under `configs/shared` until Phase 2 removes
those references.

Proposed structure:

```text
bootstrap
bin/
  niriland
  niriland-launch-browser
  niriland-pkg
  niriland-update
src/niriland/
  common.sh
  config.sh
  migrations.sh
  plan-output.sh
  sudo-session.sh
  commands/
    plan.sh
    status.sh
configs/
  home/
  shared/
  system/
packages/
  base.packages
  dev.packages
  gaming.packages
  desktop.packages
  laptop.packages
profiles/
  desktop.conf
  laptop.conf
migrations/
installer/
  install
  lib/
  steps/
tests/
docs/
machine.local.example
machine.local.conf       # gitignored
```

Only commands in `bin/` are public executables. Code under `src/niriland/` is
sourced implementation. The active fresh-install flow lives under `installer/`
until `niriland apply` can replace it without dropping installation support.
Stateful post-install implementations will live under
`src/niriland/postinstall/` when Phase 5 defines their safe command contracts.

`machine.local.conf` and the tracked profile files are data, not executable
shell. Their parser accepts only known keys and values and must never `source`
them. The first local file version only needs:

```ini
profile=desktop
```

Package manifests are grouped by why a package is installed, not by package
repository:

- `base.packages`: required on every machine;
- `dev.packages`: shared development tools;
- `gaming.packages`: Steam, Prism Launcher/Minecraft, and shared gaming tools;
- `desktop.packages`: desktop-only packages, including the additional full
  gaming stack where appropriate;
- `laptop.packages`: laptop-only hardware, power, or portability packages.

Profiles compose complete manifests rather than selecting individual entries:

```ini
# profiles/desktop.conf
package_sets=base,dev,gaming,desktop

# profiles/laptop.conf
package_sets=base,dev,gaming,laptop
```

This keeps package reasons visible without introducing a selector language such
as `gaming.prismlauncher`. If a package applies only to one machine, it belongs
in `desktop.packages` or `laptop.packages`. If a third machine later needs the
same subset, that is evidence for extracting a new shared manifest.

Every manifest line names both source and package. Examples:

```text
extra/noctalia
extra/niri
aur/noctalia-greeter
```

Use official Arch repositories (`core`, `extra`, and `multilib`) wherever
possible. CachyOS, Chaotic-AUR, and AUR entries remain explicit exceptions. This
makes the manifests understandable on CachyOS while reducing avoidable distro
coupling.

## Configuration deployment

Everything under `configs/home/` is symlinked to the corresponding path in the
user's home. Planning checks whether the target exists, has the correct type,
and points to the correct tracked source. Applying backs up conflicts before
creating or correcting the link.

Direct links into the working tree mean a local Git edit or fast-forward changes
the active configuration immediately. This is intentionally a live mode, not
complete Terraform-style isolation. `niriland update` must therefore fetch and
show the upstream diff before the user approves the fast-forward. Plan/apply
protects link topology, but cannot stage content behind a direct symlink. Apply
must never replace an existing file or link without storing it in the Niriland
backup area and reporting the exact recovery path.

### Ownership boundaries

- Everything under `configs/home/`: symlink into the user's home.
- Everything under `configs/system/`: root-owned copy to its declared absolute
  target, including `/etc`, PAM, greetd, initramfs, and system systemd units.
- Generated configuration: generated into state/cache and tracked by source
  plus hash.
- Application state, credentials, databases, and caches: unmanaged and never
  tracked.
- Configuration that an application writes back may only be symlinked when the
  application is known to preserve the link.

## Noctalia settings

Track every user-controlled Noctalia settings file, including settings written
by the GUI. Normal TOML configuration lives under
`configs/home/.config/noctalia/`. The GUI-written
`~/.local/state/noctalia/settings.toml` is represented by
`configs/home/.local/state/noctalia/settings.toml` and symlinked like any other
managed user file.

A GUI change therefore writes through the symlink and appears as an ordinary
Git working-tree change. `niriland status` and `niriland plan` report the dirty
tracked file, and `niriland update` refuses to fast-forward until the user has
reviewed and either committed, reverted, or otherwise resolved it. Do not track
the whole Noctalia state directory: runtime cache, logs, plugin data,
credentials, and other non-settings state remain unmanaged.

Implementation must verify this against the current v5 schema and
`noctalia config validate`. Configuration documentation:
<https://docs.noctalia.dev/noctalia/configuration/>.

## Desired, actual, and applied state

Niriland must keep three concepts separate:

1. Desired state comes only from repository manifests, configuration, and the
   local profile selector.
2. Actual state is read from the filesystem, pacman, systemd, and relevant
   domain tools.
3. Applied state is a small receipt describing what Niriland previously
   applied.

Applied state lives under `~/.local/state/niriland/` and is never a source of
desired state. It may contain resource IDs, source hashes, targets, timestamps,
package reasons, and backup references, but no secrets. Deleting cache must not
destroy ownership history.

Each resource receives a stable ID. Apply writes its receipt after each
successful resource so an interrupted run can resume while still showing the
unfinished plan. Niriland must not claim a false global transaction. Package
and system resources instead need concrete preflight, backup, and recovery
steps.

## Command model

Consolidate the overlapping helpers around one Bash entry point:

```text
niriland plan
niriland apply
niriland plan --prune
niriland apply --prune
niriland status
niriland update
niriland postinstall <action>
```

Semantics:

- `plan` is read-only and reports configuration, package, system, and stateful
  drift.
- `apply` enforces desired state but does not delete undeclared packages.
- `plan --prune` adds proposed removals for undeclared explicit packages to the
  read-only plan.
- `apply --prune` applies normal convergence plus the exact reviewed removal
  transaction after an additional explicit confirmation.
- `status` gives a short machine and receipt overview without package sync.
- `update` previews the upstream Git diff, fast-forwards after approval, uses
  Topgrade as the system and user-tool upgrade engine, runs pending migrations
  once, and then plans/applies additive and corrective drift. It reports
  undeclared packages but does not remove them.
- `postinstall` runs named stateful actions with their own plan, apply, verify,
  and revert flows.

There is no `adopt package` command. Keeping an untracked package means adding
its `repository/package` entry to the appropriate tracked manifest. A plan may
suggest the likely manifest, but must not edit package policy automatically.

`niriland-update`, `niriland-sync-base-config`, and setup scripts should not
survive as independent implementations. Thin compatibility wrappers may
temporarily delegate to `niriland`, then be removed with documented migration
notes.

The interactive package workflow behind `niriland-pkg` is an exception. The
current implementation must be replaced, but the fast Zsh workflows such as
`npi` and their fuzzy package browser are accepted user-facing behavior. Before
choosing the replacement, research the current Omarchy package picker and
maintained Arch package browser/TUI alternatives. Compare adopting an existing
tool with keeping a small Niriland-owned FZF frontend. The selected design must:

- search official repositories and AUR sources without hiding package origin;
- provide useful package and PKGBUILD previews before installation;
- preserve fast query and multi-select behavior from the shell;
- avoid non-interactive installation defaults for unreviewed AUR packages;
- never edit tracked package manifests implicitly; and
- leave an interactively installed explicit package visible as untracked drift
  until it is deliberately added to a manifest or selected in a prune plan.

The final command name may remain `niriland-pkg` or become a thin alias to a
`niriland` subcommand. Preserve the short Zsh aliases independently of that
implementation decision.

Browser and web application launchers may remain as focused runtime tools. VM,
certificate, fingerprint, and WoW setup must either become explicit
post-install actions or be removed if the current implementation has no clear,
active owner.

## Update migrations

Keep versioned migration scripts under `migrations/`. They exist for one-time
transitions that cannot be expressed safely as ordinary convergent resources,
such as moving state, translating an old configuration shape, or undoing an old
system customization.

Each migration has a stable ID and supports a small plan/apply contract. It
must be idempotent, describe its intended changes, and stop safely when its
preconditions are ambiguous. Successful migration IDs and source hashes are
recorded under `~/.local/state/niriland/migrations/`. A migration that has
already succeeded must never be edited; add a new migration instead.

`niriland update` runs this sequence:

1. reject an unresolved dirty working tree;
2. fetch and preview the upstream fast-forward;
3. fast-forward after confirmation;
4. discover pending migrations and include them in the update plan;
5. initialize sudo keepalive for the approved mutating work;
6. run Topgrade once with the reviewed tracked configuration;
7. run pending migrations in lexical order and record each success;
8. run normal `niriland apply` without prune;
9. validate and report any residual drift.

A failed migration stops the update before later migrations and reconciliation.
The next update resumes from the first migration without a success receipt.
Migrations never bypass the normal backup and recovery requirements, and update
never uses `--prune` implicitly.

Niriland owns update orchestration, Git safety, migrations, reconciliation, and
the sudo-session lifecycle. Topgrade owns the actual distribution and
user-tool upgrades; `niriland update` must not duplicate its package-manager or
toolchain steps. Phase 4 must revisit the tracked Topgrade configuration before
connecting it to this flow. Replace the copied upstream example with a minimal
owned configuration and verify the current schema. In particular, decide one
owner for sudo keepalive and Snapper snapshots, remove the DMS-specific updater
hook, review Paru and language-tool update coverage, prevent recursive Niriland
invocation, and define which Topgrade failures stop later migrations and apply.

When the migration framework first lands, every retained legacy migration needs
a read-only satisfaction check. If the machine already satisfies it, update
records a no-op success receipt instead of replaying the old mutation. The
accepted common-baseline migration is removed rather than enrolled in the new
framework.

## Packages and drift

Package planning must classify at least:

- missing: declared but not installed;
- managed: declared and installed;
- source drift: installed from a different source than declared;
- untracked explicit: explicitly installed but not declared by the selected
  profile;
- protected: distribution, boot, hardware, or recovery critical and never an
  automatic prune candidate;
- foreign: unavailable from enabled repositories;
- orphan: pacman's orphan classification, reported separately from Niriland
  ownership.

The first apply on an existing machine records installed desired packages as
managed without reinstalling them. Other explicit packages remain visible as
untracked until the user adds them to a manifest or applies a prune plan.

`apply --prune` must:

1. show the exact pacman transaction;
2. exclude protected, base, boot, hardware, and recovery packages;
3. preserve package reasons correctly;
4. create or require a fresh system snapshot when snapshot support is active;
5. require explicit confirmation;
6. stop if the transaction would remove a declared or protected package;
7. never remove save games, Wine prefixes, Steam libraries, or other home data.

Normal `update` must not enable prune implicitly. It ends with a clear residual
plan when untracked packages remain so drift is visible rather than hidden.

Package manifests use `repository/package` entries such as `extra/noctalia` and
`aur/noctalia-greeter`. The resolver validates that the source exists and that
the selected package matches it. Official `core`, `extra`, and `multilib`
packages are preferred. `cachyos`, `chaotic-aur`, and `aur` entries are allowed
only where the manifest intentionally depends on them. The workflow must not
depend on Paru `SkipReview`, and no flow may introduce a partial upgrade through
`pacman -Sy`. A source-qualified top-level package may still resolve
dependencies from higher-priority CachyOS repositories; source reporting must
show that transaction detail without pretending the whole dependency graph was
pinned.

### Current repository snapshot

The 2026-08-23 exact-name audit provides this starting point. It must be rerun
programmatically before implementing the package phase:

- 125 unique declared package names;
- 101 available from Arch `core`, `extra`, or `multilib`;
- 18 more available from Chaotic-AUR but not an Arch official repository;
- 4 absent from all enabled sync databases: `1password`, `1password-cli`,
  `dsearch-bin`, and `t3code-nightly-bin`;
- 2 CachyOS-only gaming meta packages that must be expanded into explicitly
  selected capabilities instead of moved blindly to AUR;
- 477 explicitly installed packages on the desktop, of which 352 are not in a
  current manifest and must be classified before prune is enabled.

A later Arch plus Chaotic migration would therefore add almost no AUR builds to
the current declared surface. Pure Arch without Chaotic needs source decisions
for 22 current declarations. These figures are a dated snapshot, not a
permanent truth. Full evidence and package names are in [`RESEARCH.md`](RESEARCH.md).

## Sudo workflow

Remove the current password-in-environment model. Mutating workflows must:

1. call `sudo -v` interactively once;
2. start a background loop that runs `sudo -n true` approximately every 60
   seconds;
3. store the loop PID locally and always stop it through `trap`;
4. never store, export, or reuse the password as a LUKS secret;
5. use sudo only around the concrete privileged command;
6. optionally finish with `sudo -k` according to the selected policy.

Read-only `plan`, including `plan --prune`, must not start keepalive. Only
install, apply, update, and stateful post-install actions may do so, and only
after displaying their plan. Implementation must follow
`~/git/docs/research/workstations/omarchy-sudo-keepalive.md`.

## FDE/TPM as a reversible post-install workflow

Remove FDE from the default installer step sequence. The replacement must
provide at least:

```text
niriland postinstall fde status
niriland postinstall fde plan-enable
niriland postinstall fde enable
niriland postinstall fde verify
niriland postinstall fde plan-disable
niriland postinstall fde disable
```

Enable must discover the actual LUKS2 device, verify a recovery passphrase,
back up relevant boot/initramfs/crypttab files, enroll the TPM token, and
validate the generated boot configuration before reboot. It must report the
workflow as pending until a user-controlled reboot proves the complete boot
chain.

Disable must first prove that a working recovery passphrase or keyslot remains.
It then removes the TPM token and related configuration and regenerates and
validates initramfs/boot configuration. It must never remove the final recovery
method. Display recovery commands and backup paths before reboot.

## Noctalia migration

Move to Noctalia in two controlled steps:

1. Install and validate Noctalia v5 configuration under Niri while retaining
   DMS as a documented fallback.
2. Switch greetd to Noctalia Greeter, validate TTY recovery and login, and only
   then remove DMS, Quickshell, greeter packages, and configuration.

Before changing the greeter, back up `/etc/greetd/config.toml`. The plan must
show the command that can restore the previous greeter from a TTY. A failed
shell or greeter migration must not leave the machine without a login path.

The manifests pin the current sources as `extra/noctalia` and
`aur/noctalia-greeter`. Noctalia is available through the official Extra
repository on CachyOS, while the greeter is maintained by the Noctalia team and
distributed through AUR. Recheck sources and version requirements during
implementation because v5 remains a fast-moving target. Current Arch package:
<https://archlinux.org/packages/extra/x86_64/noctalia/>.

## Roadmap reconciliation

Close or move these roadmap items without new implementation:

- Close Bluetooth as working on both machines.
- Move multiplexing and TUI launcher helpers to Herdr.
- Replace the DMS launcher plugin decision with standard desktop entries and
  Noctalia.
- Remove Flutter opt-in from Niriland together with its helper.
- Record Fedora and Hyprland only as later platform considerations.

Incorporate these roadmap items into the rewrite:

- Vesktop and file dialogs: keep `default=gnome;gtk`, route Access,
  Notification, and FileChooser explicitly to GTK, and route Secret to
  gnome-keyring. The explicit FileChooser route is required because the GNOME
  backend in the current Niri session exposes settings but not FileChooser.
  Brave Origin downloads and 1Password attachments currently fail with
  `No such interface org.freedesktop.impl.portal.FileChooser`, while Firefox's
  native GTK chooser works. The Vencord
  `WebScreenShareFixes` plugin is enabled, but it only removes Discord's bitrate
  cap and does not provide portal capture. Validate and encode the portal state
  as the requirement and the plugin as an optional quality preference, without
  copying session or cache data.
- Desktop entries: validate every `.desktop` file, resolve every `Icon=`
  reference, and normalize PNG canvas and scaling. Messenger already points to
  `https://www.facebook.com/messages/`; crop or replace its logo so it renders
  at the correct size in launchers.
- Suspend then hibernate: implement it as an explicit machine-aware
  `niriland postinstall hibernate` workflow with status, plan, enable, verify,
  and disable behavior. It needs disk-backed swap, resume/initramfs validation,
  and Noctalia integration and must not enter the safe baseline.
- Zathura: close the item because the current setup is already acceptable.
  Multiplexing still moves to Herdr.
- Environment: audit every existing variable and replace `90-dms.conf` with
  `90-niriland.conf`, containing only overrides still proven necessary for
  Niri, Noctalia, or the selected applications. Remove global `GDK_BACKEND`,
  `ELECTRON_OZONE_PLATFORM_HINT`, `OZONE_PLATFORM`, forced SDL/Qt backends, and
  redundant session identity unless a current application-specific test proves
  one is required.
- Installer/update: the reconciler model addresses prompt flow, sudo, moving
  FDE out, resumability, package source review, and update noise.
- Tooling: move shared developer tools to `dev.packages` and compose that
  manifest through profiles. Other purpose-based manifests make installation
  reasons visible without duplicating package names. Also fix the Zed/Typst PDF
  flow, attach the Rust i686 target to the relevant desktop gaming/build path,
  and use one small shared Bash library for scripts.

After reconciliation, `docs/ROADMAP.md` should only contain genuinely remaining
repository work. Completed historical sections may be shortened or left to Git
history so they do not compete with this plan.

## Implementation phases

### Phase 1: Contract and safe foundation

Scope:

- add a strict parser for `machine.local.conf` and a tracked example;
- add tracked desktop/laptop profiles and the `base`, `dev`, `gaming`,
  `desktop`, and `laptop` manifest contract without installing packages yet;
- establish stable resource IDs, a plan output format, the state directory,
  and fake command fixtures for tests;
- define the versioned migration contract and receipt format without running
  existing migrations yet;
- implement the sudo keepalive helper without connecting it to read-only plan;
- remove the tracked VSCodium runtime database, ignore its `globalStorage`
  directory, and remove the machine-specific Sodium fingerprint from the
  Minecraft pack;
- remove the unsafe legacy FDE step and its password-handling helpers;
- remove `cleanup`, the common-baseline migration, and accepted obsolete
  helpers and references;
- reconcile `docs/ROADMAP.md` with this plan.

Acceptance:

- the parser rejects unknown keys, values, and shell syntax;
- `plan` runs completely read-only against a temporary HOME and displays the
  selected profile;
- no live configuration, packages, or system files change;
- Bash syntax checks and ShellCheck pass for changed scripts;
- documentation has one clear source of truth for active rewrite work.

Stop after this phase. Review the design, plan output, and deletion list before
migrating configuration or package ownership.

### Phase 2: Configuration and package reconciler

Scope:

- remove the remaining runtime references to `configs/shared` after
  tracing Niri, Ghostty, and Zsh includes;
- implement home symlink and root-owned system copy planning, backup, and apply;
- finish the XDG Zsh layout and remove old modules, the root `.zshrc`, and
  [`ZSH_REWRITE_NOTES.md`](ZSH_REWRITE_NOTES.md);
- remove the marketplace patch and other generated state;
- implement package resolution, ownership receipts, source classification,
  manifest suggestions, and `plan --prune`;
- expand the two CachyOS gaming meta packages into reviewed explicit package
  ownership and classify all currently unmanifested explicit packages before
  allowing a removal plan;
- map installer steps to stable resources instead of replaying them blindly.

Acceptance:

- a temporary-HOME test can plan, apply, and plan to an empty final plan;
- a second apply is idempotent;
- replacing an existing home target with a symlink can be restored from the
  displayed backup;
- no configuration include points to removed `base` or `modules` paths;
- package planning is testable with fake pacman data without touching the host;
- no runtime database, credential, or cache is tracked.

Stop after temporary-HOME and desktop dry-run validation. Do not apply to the
laptop until the desktop result has been reviewed.

### Phase 3: Niri and Noctalia v5

Scope:

- replace DMS configuration, autostart, packages, and environment with
  Noctalia v5;
- symlink all user-controlled Noctalia settings, including
  `.local/state/noctalia/settings.toml`;
- preserve GNOME screen capture and explicitly route FileChooser to GTK with
  `org.freedesktop.impl.portal.FileChooser=gtk`;
- remove the researched obsolete global backend overrides;
- install and validate Noctalia Greeter with DMS and TTY fallback;
- remove DMS and Quickshell only after a successful login and session test.

Acceptance:

- `niri validate` and `noctalia config validate` pass;
- Vesktop can share the full screen and an individual window;
- Brave Origin can download a file and 1Password can attach one through the
  desktop file chooser;
- Noctalia starts exactly once per Niri session;
- login, lock, logout, reboot, and TTY recovery are tested;
- a GUI settings change appears as a normal tracked Git diff and survives on
  the second machine after that change is reviewed and transferred.

Stop after the desktop test. Laptop cutover is a separate explicit apply.

### Phase 4: Update, prune, and script consolidation

Scope:

- replace installer-step replay with the fetch/preview/apply/validate workflow;
- use Topgrade as the single upgrade engine invoked by `niriland update` and
  reduce its tracked configuration to reviewed Niriland-owned settings;
- run pending versioned migrations once during update and resume safely after a
  migration failure;
- implement resumability and short, relevant prompts;
- implement `apply --prune` with a protected set, snapshot, and transaction
  guard;
- migrate or remove old `niriland-*` wrappers while preserving the interactive
  `npi` package-discovery workflow behind a redesigned implementation;
- research the current Omarchy package picker and maintained Arch package
  browser/TUI alternatives before choosing that implementation;
- split package ownership into the purpose-based manifests composed by each
  profile;
- remove local AI, Flutter, Helium, and Helix flows;
- document the package source audit and CachyOS dependencies.

Acceptance:

- normal update does not replay irrelevant installer steps;
- update invokes Topgrade exactly once and does not duplicate package-manager,
  Cargo, mise, or other toolchain upgrades owned by its reviewed configuration;
- the tracked Topgrade configuration contains only intentional current options,
  has no DMS hook, and does not compete with Niriland for sudo keepalive or
  snapshot ownership;
- update runs each pending migration exactly once and records its source hash;
- update leaves either an empty plan or a clearly reported intentional
  residual plan;
- no package can be removed without `plan --prune`, `apply --prune`, and the
  removal confirmation;
- `npi` still provides a fast source-aware package picker, and packages installed
  through it become visible as untracked until deliberately manifested;
- an interrupted apply can resume from receipts;
- a second update without source changes is idempotent and quiet.

### Phase 5: Stateful post-install work

Scope:

- build and test the reversible FDE/TPM workflow;
- build `niriland postinstall hibernate` as a separate, reversible,
  machine-aware workflow;
- replace the certificate helper with an explicit direct-use versus global
  trust-anchor workflow;
- replace the fingerprint helper with a laptop-only, reversible workflow that
  defaults to Noctalia lock-screen use and leaves sudo/polkit password-based;
- review VM and WoW helpers and keep only active flows with plan, apply, verify,
  and recovery behavior.

Acceptance:

- every flow has read-only status and plan commands;
- enable and disable/revert paths are documented;
- device discovery and recovery checks stop on ambiguity;
- no stateful action runs through normal install or update;
- reboot-requiring work has a tested recovery path.
- FDE and hibernate apply stop in a documented pending-verification state until
  the user completes the required reboot or resume test.

### Phase 6: Desktop polish and documentation

Scope:

- validate and normalize web application desktop entries and icons;
- finish the Messenger logo while preserving the Facebook Messages URL;
- finish the Zed/Typst PDF flow and leave the accepted Zathura setup unchanged;
- update README, migrations, troubleshooting, and the installation guide;
- perform a final drift audit on both machines.

Acceptance:

- `desktop-file-validate` passes for every managed entry;
- all icons resolve and render consistently;
- both profiles produce an empty plan after apply;
- the laptop has the gaming baseline without desktop-only extras;
- the desktop has the declared full gaming stack;
- documentation describes the actual command surface and recovery workflows.

## Validation strategy

No phase should be validated by casually running the entire installer on the
host. Instead use:

- `bash -n` for every changed Bash script;
- `shellcheck` for every changed Bash script;
- a temporary HOME and fake command runner for parser, resolver, plan, and
  apply tests;
- golden/output tests for resource and package plans;
- `zsh -n`, `niri validate`, `noctalia config validate`, TOML/JSON validation,
  and `desktop-file-validate` where relevant;
- read-only pacman queries for actual state and a separate test fixture for
  removal behavior;
- final `git diff --check`, status, diff review, and untracked-file audit;
- a manual smoke test on the desktop before applying the same phase to the
  laptop.

Define the complete local gate as a repository command once the test harness
exists. Until then, report the exact checks run, failed, skipped, or unavailable
for each phase.

## Recovery and safety

- Every overwritten target receives a timestamped backup under Niriland state.
- System and package changes have preflight checks and concrete recovery
  instructions.
- Package removal happens only through explicit `apply --prune`, never through
  update or plain apply.
- Greeter migration preserves TTY access and the previous greetd configuration
  as a fallback.
- FDE disable preserves at least one verified recovery passphrase or keyslot.
- Git update is fast-forward only and previewed before live symlinked
  configuration changes.
- A dirty working tree or unknown machine configuration blocks mutating flows.
- The agent does not run install, package removal, sudo apply, or reboot without
  a new explicit user request for that concrete implementation or test.

## Open decisions before later phases

- VM and WoW setup remain unclassified. Do not remove or redesign them until
  their current use is confirmed in Phase 4.

## Next step

Phase 1 is implemented locally and must be reviewed together with its plan
output, deletion list, tests, and [`RESEARCH.md`](RESEARCH.md). The next
implementation unit is Phase 2. It remains non-live until its temporary-HOME,
fake-pacman, and desktop dry-run evidence has been reviewed; no package or live
configuration apply is implied by this plan.
