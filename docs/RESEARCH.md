# Niriland rewrite research

Research date: 2026-08-23

This document records implementation evidence for the maintenance rewrite in
[`PLAN.md`](PLAN.md). It supports that plan; it does not replace the phase order
or authorize applying changes to either workstation.

The local inspection in this pass was read-only. No package transaction,
service change, privileged command, live config deployment, migration apply,
reboot, suspend, or hibernation test was performed.

## Conclusions

- Stay on CachyOS for this rewrite. Keep the package model portable enough that
  a later Arch migration is mostly a repository-policy change.
- Keep purpose-based package sets and compose them through the desktop and
  laptop profiles. Source remains explicit metadata on each package.
- User configuration should be symlink-only. System configuration should be
  copied with root, backup, plan, verify, and revert behavior.
- Track Noctalia's hand-written config and its GUI-written settings file, but
  not its entire state directory.
- Keep interface-specific Niri portal routing. GNOME provides screen capture,
  while GTK must explicitly provide FileChooser. Vesktop's Vencord screen-share
  plugin is a quality tweak, not the mechanism that makes portal capture work.
- Remove most global Wayland backend overrides. In particular,
  `GDK_BACKEND` conflicts with Niri's screencast guidance and
  `ELECTRON_OZONE_PLATFORM_HINT` was removed in Electron 38.
- Keep the certificate and fingerprint workflows, but replace both legacy
  implementations. The certificate trust refresh currently does not consume
  the directory where the certificate is copied, and the fingerprint PAM
  edits are unsafe for `sudo` and polkit.
- Suspend-then-hibernate cannot work on this desktop today because its only
  swap is zram. It needs disk-backed swap plus a verified resume path.
- The existing TPM auto-unlock state is machine-specific post-install state.
  It must never return to the normal install or update path.
- Pruning must be based on Niriland ownership, not merely pacman's explicit or
  orphan flags. The current desktop has too much historical explicit state for
  automatic pruning to be safe.

## Package model and CachyOS portability

### Current repository snapshot

The active sync databases on this desktop are:

```text
cachyos-v3
cachyos-core-v3
cachyos-extra-v3
cachyos
core
extra
multilib
chaotic-aur
```

A read-only exact-name audit covered the 125 unique package names in the five
non-placeholder manifests. Classification used the active sync database
contents, with Arch official repositories taking precedence over any optimized
CachyOS copy of the same package.

- 101 packages are available from Arch `core`, `extra`, or `multilib`.
- 18 more are available from `chaotic-aur` but not an Arch official repository.
- 4 are absent from all active sync databases: `1password`, `1password-cli`,
  `dsearch-bin`, and `t3code-nightly-bin`.
- 2 are CachyOS-only: `cachyos-gaming-meta` and
  `cachyos-gaming-applications`.

Consequences:

- CachyOS to Arch while retaining Chaotic-AUR does not turn most of the setup
  into AUR packages. Only the four already non-repository packages need an AUR
  or vendor source decision.
- The two CachyOS gaming meta packages should disappear from the portable
  manifests. Their actual desired members should be declared explicitly in
  `gaming.packages` or `desktop.packages`.
- A pure Arch setup without Chaotic-AUR would need source decisions for 22
  packages: the 18 Chaotic-only entries plus the four currently absent from
  sync databases. That is a separate trust and maintenance tradeoff.
- `extra/noctalia` is portable. On this snapshot it is available as
  `5.0.0_beta.8-1` in Arch Extra and as an optimized build in
  `cachyos-extra-v3`.
- `noctalia-greeter` is available as a CachyOS binary, but the portable source
  is `aur/noctalia-greeter`, maintained by `noctalia-dev`. The AUR snapshot was
  version `1.2.1-1` during this audit.

The AUR is explicitly unsupported user-produced content and requires reviewing
the `PKGBUILD` and related files. Niriland should never hide that review behind
an unattended update. See the [Arch User Repository guidance](https://wiki.archlinux.org/title/Arch_User_Repository).

### Source-qualified targets

Pacman supports `repository/package` targets, and a read-only preview confirmed
that `extra/niri` and `extra/noctalia` select the official Arch builds even
when higher-priority CachyOS optimized repositories contain the same names.
Pacman's `--print` mode can preview a sync transaction without applying it; the
format includes the selected repository. See [pacman(8)](https://man.archlinux.org/man/pacman.8.en).

There is one important limitation: qualifying the top-level package does not
pin all of its dependencies. For example, previewing `extra/noctalia` on this
desktop still resolves some dependencies from `cachyos-extra-v3`, according to
normal repository priority. That is acceptable while running CachyOS. Complete
independence would require disabling the CachyOS repositories for the entire
transaction, which is outside this rewrite's goal.

Recommended manifest rules:

- use `core/name`, `extra/name`, or `multilib/name` where an Arch official
  source exists;
- use `chaotic-aur/name` only for reviewed binary-repository exceptions;
- use `aur/name` for reviewed AUR recipes;
- do not encode CachyOS optimized repository names for packages also available
  from Arch;
- replace CachyOS meta packages with the explicit capabilities Niriland wants;
- let a parser reject unqualified package names after the Phase 2 migration.

### Installed package drift

The current desktop has:

```text
477 explicitly installed packages
125 declared package names, all explicitly installed
352 explicit packages not present in a current manifest
32 packages absent from the active sync databases
21 pacman orphans
```

This does not mean 352 packages should be removed. CachyOS installation
profiles marked many platform and dependency packages explicit, including boot,
filesystem, driver, printing, DMS, and gaming-related packages. Pacman records
installation reason, not Niriland ownership. `pacman -Qe` and `pacman -Qd`
expose that distinction, while `pacman -Qdt` identifies only unneeded
dependency packages. See [pacman package reason guidance](https://wiki.archlinux.org/title/Pacman).

The safe model is therefore:

1. classify the complete explicit set before enabling prune;
2. protect boot, kernel, firmware, storage, encryption, graphics, network,
   package-manager, and active profile requirements;
3. distinguish undeclared explicit packages, foreign packages, and orphans;
4. preview the exact pacman removal transaction;
5. require `--prune` and confirmation for removal;
6. never include home data, Steam libraries, Wine prefixes, saves, or caches as
   package-owned removal targets;
7. record why a retained package is adopted into a package set.

This also explains why a separate `adopt package` command is unnecessary now.
Adoption means editing the appropriate reviewed manifest, not mutating hidden
state through a command.

## Profiles and package ownership

The selected structure remains sound:

```text
base     shared workstation baseline
dev      shared development capability
gaming   shared Steam and Minecraft-capable gaming baseline
desktop  desktop-only extended gaming and hardware packages
laptop   laptop-only power, hardware, and explicit extras
```

Profiles compose these sets:

```text
desktop = base + dev + gaming + desktop
laptop  = base + dev + gaming + laptop
```

This avoids duplicating package names while keeping the reason for each package
visible. Prism Launcher belongs in `gaming.packages`; a laptop-specific extra
belongs in `laptop.packages`. No generic free-form `extra_packages` field is
needed until there is a real third-machine case that cannot be represented by a
reviewed package set.

## Configuration deployment

### User configuration

Symlink-only deployment is the correct model for `configs/home/`:

- Git is the canonical content source.
- `plan` compares the desired link target, existing target type, and content.
- `apply` creates parent directories and relative or absolute links according
  to one consistent repository convention.
- an existing unmanaged file is backed up before replacement;
- an unmanaged directory is never replaced recursively without an exact plan;
- dangling links and links to the wrong checkout are drift;
- a fast-forward changes live linked content immediately, so `update` must
  preview the upstream diff before moving Git HEAD.

Symlinks intentionally remove copy-mode divergence. They do not create a true
Terraform transaction: once the repository fast-forwards, linked content has
changed. The safe boundary is therefore approval before fast-forward, followed
by migrations, reconciliation, and validation in one explicit `update` flow.

### System configuration

`configs/system/` remains copy-based because its targets are under `/etc` or
other privileged locations. Every resource needs:

- an exact destination and file mode;
- a content comparison in `plan`;
- a timestamped backup before replacement;
- atomic installation where practical;
- domain validation before declaring success;
- a revert operation for optional post-install features;
- no blanket recursive copy into `/etc`.

## Noctalia v5 under Niri

Noctalia v5 is currently beta software, so config schema changes remain a real
migration concern. The [Noctalia configuration documentation](https://docs.noctalia.dev/noctalia/configuration/)
defines two relevant user-controlled layers:

- hand-written TOML fragments under `~/.config/noctalia/`, loaded in sorted
  order;
- GUI-written overrides in `~/.local/state/noctalia/settings.toml`, loaded
  last.

Noctalia explicitly preserves a symlink for `settings.toml` and writes through
it. That makes tracking and symlinking this one state file supported behavior.
Do not symlink the full state directory: internal runtime state, plugin data,
logs, caches, and potentially private data are not shared configuration.

Noctalia may migrate its own GUI settings and stamp a newer schema. Hand-written
config is not automatically rewritten. Niriland should therefore:

- run `noctalia config validate` against tracked config;
- detect whether the tracked `settings.toml` changed after opening the GUI;
- stop `update` before fast-forward when that tracked target has uncommitted
  changes;
- treat upstream config migration warnings as a source maintenance task, not
  as a reason to overwrite the tracked file.

The official startup guidance recommends compositor autostart. Under Niri,
start Noctalia exactly once with a Niri startup entry; use daemon mode only if
the startup mechanism requires the command to return. See [running the shell](https://docs.noctalia.dev/noctalia/getting-started/running-the-shell/).
Do not also create an independent user service unless a later test proves it is
needed.

Noctalia claims notifications and the status-notifier host in a non-Plasma
session. DMS and other notification/tray hosts must be stopped before the final
cutover. The package's [packaging notes](https://github.com/noctalia-dev/noctalia/blob/main/PACKAGING.md)
also recommend a Secret Service provider; the existing GNOME Keyring path fits
that requirement.

### Noctalia Greeter

The [greeter configuration documentation](https://docs.noctalia.dev/greeter/configuration/)
separates declarative `/var/lib/noctalia-greeter/greeter.toml` from mutable
`sync.toml`. The declarative file wins where both specify a value. Greetd starts
with a minimal environment, so the configured session command must use the full
path returned by `command -v noctalia-greeter-session`.

The safe cutover is:

1. install and validate Noctalia while DMS remains available;
2. prepare the greeter config with correct ownership for the greeter account;
3. retain a known TTY login and record recovery commands;
4. switch greetd only in an explicit apply;
5. verify one complete login and logout cycle;
6. remove the DMS greeter and shell only after that verification.

The upstream [greeter README](https://github.com/noctalia-dev/noctalia-greeter/blob/main/README.md)
and [packaging notes](https://github.com/noctalia-dev/noctalia-greeter/blob/main/PACKAGING.md)
should be rechecked at implementation time because the package is new and
changing quickly.

## Screen sharing, file dialogs, and portals

The live portal config currently preserves Vesktop screen sharing but does not
provide working file dialogs:

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
```

On 2026-08-24, `xdg-desktop-portal` repeatedly logged that the selected backend
did not expose `org.freedesktop.impl.portal.FileChooser`. Introspection showed
that the GNOME backend exposed settings only in the Niri session, while the GTK
backend exposed FileChooser. Brave Origin downloads and 1Password attachments
failed. Firefox's native GTK chooser worked.

Phase 3 must preserve the existing entries and add this interface-specific
route:

```ini
org.freedesktop.impl.portal.FileChooser=gtk;
```

After restarting the GTK and main portal user services, validation must cover
Brave Origin download, 1Password attachment, and Vesktop full-screen and window
sharing. The tracked file currently says only `default=gtk`, so copying it
unchanged would regress the known screen-sharing state.

Niri's [screencasting documentation](https://github.com/niri-wm/niri/blob/main/docs/wiki/Screencasting.md)
requires a proper D-Bus session, PipeWire, and
`xdg-desktop-portal-gnome`. Niri's [important software guidance](https://github.com/niri-wm/niri/wiki/Important-Software)
recommends both GNOME and GTK portals and warns that globally forcing
`GDK_BACKEND` can break the screencast portal. The portal selection file may set
interface-specific providers and ordered fallbacks, as defined by the
[portal configuration specification](https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html).

Vesktop's local `WebScreenShareFixes` plugin is enabled. Its current
[implementation](https://github.com/Vendicated/Vencord/blob/main/src/plugins/webScreenShareFixes.web/index.ts)
removes Discord's 2500 kbps cap for Chromium/Vesktop; it does not select the
portal or make PipeWire capture work. Preserve it as an optional quality
preference, but make the portal config the managed requirement.

Phase 3 validation must test both portal capabilities after the portal change
and again after the DMS-to-Noctalia cutover.

## Environment variable audit

The file should be renamed to a neutral name such as
`~/.config/environment.d/90-niriland.conf`, but only after each value has been
removed or justified.

- `GDK_BACKEND=wayland,x11,*`: remove. Niri explicitly warns against a global
  override because it can break the screencast portal.
- `QT_QPA_PLATFORM=wayland;xcb`: remove globally. Qt chooses a default platform;
  this variable is an override. Use an application-specific flag only for a
  demonstrated broken Qt app. See [Qt Platform Abstraction](https://doc.qt.io/qt-6/qpa.html).
- `SDL_VIDEODRIVER=wayland,x11`: remove globally. SDL's documented default is
  to try available backends in a reasonable order; the variable forces a
  target. See [SDL_HINT_VIDEODRIVER](https://wiki.libsdl.org/SDL2/SDL_HINT_VIDEODRIVER).
- `MOZ_ENABLE_WAYLAND=1`: remove from the shared baseline unless a currently
  installed Mozilla build is demonstrated to require it. Niri already provides
  a Wayland session, and this variable is a force switch rather than generic
  session identity.
- `ELECTRON_OZONE_PLATFORM_HINT=wayland`: remove. Electron 38 removed the
  variable and now selects Wayland from `XDG_SESSION_TYPE=wayland`. See
  [Electron's breaking changes](https://www.electronjs.org/docs/latest/breaking-changes).
- `OZONE_PLATFORM=wayland`: remove. The documented Chromium control is the
  `--ozone-platform` command-line switch, and current Electron does automatic
  session selection.
- `XDG_SESSION_DESKTOP=niri`: remove. Niri started with `--session` sets and
  imports the relevant session identity itself. See the upstream
  [`niri-session` script](https://github.com/niri-wm/niri/blob/main/resources/niri-session).
- `TERMINAL=ghostty`: retain only if a tracked consumer is identified. Prefer
  `xdg-terminal-exec` and its preference file for desktop launches.
- `QT_QPA_PLATFORMTHEME=qt6ct`: retain if qt6ct continues to own Qt application
  theming; it is not needed by Noctalia itself.
- `EDITOR=nvim`: retain as a normal user preference.
- `PATH=...`: keep one canonical PATH definition, remove the duplicated
  `~/.local/bin`, and verify desktop-launched apps plus interactive Zsh. Do not
  let `niriland-update` rewrite it.
- `GTK_IM_MODULE=simple`: remove unless the user deliberately wants to force
  GTK's simple compose/dead-key input method. GTK otherwise has no forced
  module; see the [GTK input-method setting](https://docs.gtk.org/gtk4/property.Settings.gtk-im-module.html).

## Sudo session workflow

The implemented Bash helper follows the intended narrow model:

1. `sudo -v` authenticates once and refreshes the timestamp;
2. a background loop runs `sudo -n true` every 60 seconds;
3. a trap stops the loop on every exit path;
4. long privileged workflows may finish with `sudo -k` to invalidate the
   current timestamp;
5. no password is stored in an environment variable, file, argument, or pipe.

By default sudo timestamps are short-lived and scoped according to sudoers
policy. `-n` prevents a background prompt and `-k` invalidates the current
timestamp. See [sudo(8)](https://www.man7.org/linux/man-pages/man8/sudo.8.html)
and [sudoers(5)](https://man7.org/linux/man-pages/man5/sudoers.5.html).

The keepalive deliberately extends the period in which processes in the same
timestamp scope may use cached authorization. It belongs only in a bounded,
interactive mutating command. It must not run for `plan` or `status`, and it
must not survive the parent process.

The original Omarchy note used the same `sudo -v` plus non-interactive refresh
pattern. Niriland additionally needs shared cleanup traps because install and
update have several exit paths.

## Migration runner

The v1 migration contract added in Phase 1 is appropriate for update-time
replay:

- stable ID from the filename;
- immutable source hash in the receipt;
- `describe`, `check`, `plan`, and `apply` operations;
- deterministic lexical discovery;
- `check` must be read-only and able to declare an already-satisfied migration;
- success receipt only after apply and postcondition verification;
- a changed source hash is blocked rather than silently replayed;
- failure stops later migrations;
- the next run resumes at the first migration without a success receipt.

Existing scripts are legacy and should remain deferred until converted. A
migration must not source machine config or another migration as executable
shell. The CLI parser should continue treating configuration as data.

Migrations are not a substitute for reconciliation. They handle one-time shape
changes; `apply` owns the durable desired state after the migration.

## TPM2 disk auto-unlock

Read-only inspection of this desktop found:

- a LUKS2 container around the Btrfs root filesystem;
- a systemd-based mkinitcpio with `sd-encrypt`;
- `/etc/crypttab.initramfs` configured with `tpm2-device=auto`;
- a detected TPM2 device;
- Secure Boot enabled;
- no privileged access to inspect or change LUKS slots in this pass.

The removed legacy helper had several problems:

- it was previously in the default install path;
- it handles the disk passphrase through a temporary file;
- it silently stores a generated recovery key under `/root`;
- it does not provide a complete plan/status/remove workflow;
- it relies on the enrollment default instead of declaring a reviewed PCR
  policy;
- it cannot prove recovery before changing boot-critical state.

`systemd-cryptenroll` supports recovery keys, TPM2 enrollment, explicit PCR
binding, and replacement with `--wipe-slot=tpm2`. Recovery keys are intended as
a fallback when hardware-token access fails. See
[systemd-cryptenroll(1)](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html)
and [crypttab(5)](https://www.freedesktop.org/software/systemd/man/latest/crypttab.html).

The replacement `niriland postinstall fde` should:

1. expose read-only status without sudo where possible and clearly mark unknown
   privileged facts;
2. resolve the exact root mapper and backing LUKS2 device again at apply time;
3. verify systemd initramfs, `sd-encrypt`, TPM presence, Secure Boot state, and
   bootloader integration;
4. require an existing password or recovery method before enrollment;
5. generate or confirm an offline recovery key and require explicit user
   acknowledgement before continuing;
6. declare the selected PCR policy explicitly; PCR 7 is the simple current
   systemd example for Secure Boot policy, while signed PCR 11 or pcrlock is a
   later, more complex option;
7. back up every changed system file and recommend a LUKS header backup stored
   off the encrypted volume;
8. rebuild initramfs and bootloader state, then stop for a user-controlled
   reboot test;
9. support removal by deleting only the managed crypttab option and wiping only
   TPM2 slots after another unlock method is verified;
10. never run from ordinary install, apply, or update.

No script can honestly verify boot recovery without a reboot. The apply result
must say "configuration written; reboot test pending," not "complete."

## Suspend then hibernate

This desktop currently has about 32 GiB RAM and only a 31.1 GiB zram swap
device. Hibernation to zram is unsupported because zram is not persistent.
There is no `resume=` or `resume_offset=` kernel parameter in the current boot
command line. Therefore suspend-then-hibernate is not currently ready.

The root filesystem is encrypted Btrfs. A suitable implementation needs:

- a disk-backed Btrfs swap file, preferably in a dedicated swap subvolume;
- enough free disk space and an explicit size policy;
- a persistent fstab entry;
- a resume location available in the initramfs;
- `btrfs inspect-internal map-swapfile -r` if a manual Btrfs resume offset is
  required;
- an initramfs and Limine rebuild when boot parameters change;
- a systemd sleep drop-in, not edits to the vendor file;
- direct hibernate validation before suspend-then-hibernate validation;
- an exact revert path.

Systemd 261 can use the UEFI `HibernateLocation` variable to record an
automatically selected swap area, but Niriland should verify that behavior on
this encrypted Btrfs and Limine setup instead of assuming it. The
[Arch suspend and hibernate guide](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)
documents zram limitations, initramfs requirements, persistent resume targets,
and the Btrfs-specific offset command.

`HibernateDelaySec=` controls the suspend interval. With no battery, systemd's
documented default is two hours. With a battery, systemd can use low-battery
alarms and optionally a configured delay; `HibernateOnACPower=` changes timer
behavior on AC. See [systemd-sleep.conf(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html).

Recommended staged verification:

1. create and activate disk-backed swap, then verify normal operation;
2. configure resume and rebuild boot artifacts;
3. perform one explicit `systemctl hibernate` with recovery access available;
4. verify resumed applications, filesystems, networking, audio, and graphics;
5. repeat hibernate at least three times before enabling the combined action;
6. test `systemctl suspend-then-hibernate` separately;
7. only then expose the action through Noctalia.

The revert command must first disable the combined action, then remove resume
configuration, rebuild boot artifacts, disable the swap entry, and finally
remove the managed swap file after confirmation.

## Fingerprint workflow

The desktop currently has neither `fprintd` nor `libfprint` installed, which is
consistent with fingerprint being a laptop-specific post-install feature.

The legacy helper should not be reused. It:

- treats an empty `fprintd-list` result as no hardware, although that can also
  mean no enrolled print;
- prepends `auth sufficient pam_fprintd.so` directly to sudo and polkit PAM
  stacks;
- synthesizes a complete `/etc/pam.d/polkit-1` file if one is absent;
- removes every matching PAM line without proving ownership;
- removes the package during revert even if another login surface uses it;
- has no backup, PAM validation, or recovery test.

Arch currently warns that fingerprint-only `auth sufficient` for `sudo`, `su`,
or polkit can allow a background process to obtain authorization through
fingerprint hijacking (CVE-2024-37408). See the [Arch fprint guidance](https://wiki.archlinux.org/title/Fprint)
and [pam_fprintd(8)](https://man.archlinux.org/man/pam_fprintd.8.en).

Noctalia v5 has its own fingerprint option and accesses fprintd through D-Bus,
but current beta reports show PAM interaction edge cases. Treat lock-screen
fingerprint support as a Phase 5 hardware test, not as proof that sudo or polkit
should use the same PAM stack.

Recommended default:

- install `fprintd` only on the laptop through an explicit post-install action;
- enroll and verify a print interactively;
- enable and test Noctalia lock-screen fingerprint support;
- leave sudo and polkit password-based;
- if sudo/polkit fingerprint is still desired later, make it a separately
  warned opt-in with exact backups, a recovery TTY, and explicit PAM tests;
- revert only Niriland-owned PAM snippets or restored backups, never arbitrary
  matching lines.

## DTU certificate workflow

The tracked file is a self-signed DTU root CA with SHA-256 fingerprint:

```text
AD:61:AC:CF:9A:75:DE:CA:01:52:2E:C5:F6:F9:55:00:
C7:3F:65:C1:16:14:9C:09:A6:AC:5A:EF:41:0A:0F:E2
```

It is valid from 2015-12-02 through 2040-12-02. It contains no private key.

The current helper copies it to `/etc/certs/Eduroam_aug2020.pem` and then calls
`update-ca-trust`. On Arch, `update-ca-trust` scans
`/etc/ca-certificates/trust-source/` and its `anchors/` subdirectory, not
`/etc/certs`. Therefore the refresh does not make that copy a global trust
anchor. See [update-ca-trust(8)](https://man.archlinux.org/man/update-ca-trust.8).

The direct `/etc/certs` path may still be intentional if a private
NetworkManager eduroam profile references it. That profile was not inspected
because it may contain identity or authentication data. The replacement must
make the ownership choice explicit:

- if NetworkManager references the file directly, keep the stable
  `/etc/certs/...` copy and remove the misleading trust-store refresh;
- if applications require a global trust anchor, install a second managed copy
  under `/etc/ca-certificates/trust-source/anchors/` and run
  `update-ca-trust extract`;
- prefer the narrower NetworkManager reference unless global trust is proven
  necessary;
- `status` must compare content, subject, issuer, expiry, and fingerprint;
- `remove` must delete only managed copies, refresh the trust store if needed,
  and warn before breaking an active network profile.

Trusting a private CA globally expands who can issue certificates accepted by
the workstation, so this distinction matters even though the certificate
itself is public.

## Desktop entries and icons

The current managed desktop entries pass `desktop-file-validate` without
errors. There are warnings for comments identical to names and hints for
multiple main categories. These are polish issues, not parser failures.

The desktop entry specification resolves a non-absolute `Icon=` value through
the active icon theme. The hicolor theme is the required fallback. See the
[Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html)
and [Icon Theme Specification](https://specifications.freedesktop.org/icon-theme/latest/index.html).

The existing deployment step already copies tracked PNGs into the hicolor
`256x256/apps` directory, but the symlink rewrite should make the repository
layout canonical instead of transforming a flat icon directory during install.
Recommended target:

```text
configs/home/.local/share/icons/hicolor/256x256/apps/niriland-messenger.png
configs/home/.local/share/applications/niriland-messenger.desktop
```

Use stable lowercase `niriland-*` names to avoid collisions with packaged icons
and case-sensitivity surprises. Messenger should continue launching
`https://www.facebook.com/messages/`. Replace or crop its icon so the mark fills
the canvas, then validate both desktop-file syntax and actual theme lookup.
Apply the same check to every managed web app: valid `Exec`, resolvable icon,
useful comment, sensible categories, and the correct URL.

## Zed, Typst, and Zathura

The tracked Zed settings configure Tinymist with:

```json
"exportPdf": "onSave",
"outputPath": "$dir/$name"
```

Those are valid Tinymist settings. Tinymist documents `onSave` and the
`$root`, `$dir`, and `$name` output variables in its
[configuration reference](https://github.com/Myriad-Dreamin/tinymist/blob/main/editors/neovim/Configuration.md).
The Zed Typst extension's example uses `"$root/$name"`; see the
[official Zed extension repository](https://github.com/zed-extensions/typst).

The remaining problem is the open action, not basic PDF export. Zed may try to
open the generated PDF as an editor buffer before the external viewer is
invoked. The Phase 6 target should be:

- retain Tinymist `onSave` export;
- pick one predictable output convention, preferably `$root/$name` for
  project-level documents or `$dir/$name` when colocated artifacts are wanted;
- add an explicit Zed task or action that launches the generated PDF with
  `xdg-open` or Zathura instead of opening it as a Zed buffer;
- test a single-file Typst document and a project whose root differs from the
  current file directory;
- keep Zathura unchanged otherwise, as already decided.

Do not add a second PDF extension or viewer merely to work around the task
routing.

## Tool consolidation

The end-state command surface remains:

```text
niriland plan
niriland apply
niriland plan --prune
niriland apply --prune
niriland status
niriland update
niriland postinstall ...
```

Disposition of current helpers:

- `niriland-update`: absorb into `niriland update` after Phase 4.
- `niriland-pkg`: replace the current implementation after researching
  Omarchy's picker and maintained Arch package browser/TUI alternatives. Keep
  the fast `npi`/FZF workflow, and expose interactively installed packages as
  untracked drift instead of editing manifests implicitly.
- `niriland-sync-base-config`: remove when user config is symlink-only.
- `niriland-setup-gaming`: absorb into profile package sets; keep Minecraft
  data import as an explicit, idempotent migration or post-install action.
- `niriland-setup-certificates` and `niriland-setup-fingerprint`: replace with
  reversible `postinstall` subcommands.
- browser and web-app launch helpers: retain as narrow runtime tools.
- TUI presentation and terminal multiplexing helpers: move to Herdr as already
  decided.

### VM helper

The VM helper is currently a one-way installer. It installs packages, appends a
libvirt firewall setting, changes group membership, enables services and a
network, changes UFW, and installs Quickemu packages. It has no status, plan,
or revert contract. It also assumes the iptables backend without checking the
current libvirt/firewall stack.

Recommendation: do not include it in the desktop profile and do not delete it
until the user decides whether local virtualization is still active. If kept,
it must become `postinstall vm` with a purpose-based package set, read-only
status, current libvirt guidance, exact system resources, and explicit revert.

### WoW helper

The WoW helper manages another Git repository and a game installation path. It
does not install the game, but it mutates the external repo and delegates to its
setup script. This is application-data orchestration rather than workstation
baseline.

Recommendation: keep it out of normal plan/apply/update. If it remains useful,
move the workflow into `wow-ui` itself or retain only a thin explicit
`postinstall wow` wrapper after reviewing that repository's setup and revert
behavior. Its default path must be machine-local rather than a shared profile
constant.

## Research-driven changes to the plan

The following points should be treated as requirements in their existing
phases:

- Phase 2 must replace both CachyOS gaming meta packages with explicit members
  before claiming Arch portability.
- Phase 2 must classify all 352 currently unmanifested explicit packages before
  prune can leave read-only preview status.
- Phase 3 must remove global `GDK_BACKEND` and
  `ELECTRON_OZONE_PLATFORM_HINT`, route GNOME screen capture and GTK
  FileChooser explicitly, and describe Vencord's screen-share plugin as an
  optional bitrate fix.
- Phase 3 must track only Noctalia's user-controlled settings, including the
  supported `settings.toml` symlink, not its whole state tree.
- Phase 5 must replace, not wrap, the certificate and fingerprint helpers.
- Phase 5 should default fingerprint support to Noctalia lock-screen use and
  leave sudo/polkit password-based.
- Phase 5 must treat the current desktop's zram-only configuration as
  hibernate-not-ready.
- Phase 5 must stop after writing FDE or hibernation boot changes until the user
  completes the documented reboot/resume test.
- Phase 6 should normalize desktop/icon names into hicolor and solve Zed's PDF
  open action without changing the accepted Zathura setup.

Two product decisions remain intentionally open:

- whether local VM support is still used on either machine;
- whether the WoW UI helper still belongs in Niriland or should live entirely
  in `wow-ui`.

Neither decision blocks Phases 1 through 4.
