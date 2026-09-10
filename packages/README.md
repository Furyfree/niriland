# Package manifest contract

Package manifests are grouped by installation reason. Profiles compose entire
manifests so a package has one clear owner:

- `base.packages`: required on every machine;
- `dev.packages`: shared development tools;
- `gaming.packages`: shared Steam and Minecraft tooling;
- `desktop.packages`: desktop-only packages and the extended gaming stack;
- `laptop.packages`: laptop-only hardware and power packages.

The target line format is `repository/package`, for example:

```text
extra/niri
extra/noctalia
aur/noctalia-greeter
```

Blank lines and lines beginning with `#` are ignored. Prefer `core`, `extra`,
and `multilib`. Use `cachyos`, `chaotic-aur`, or `aur` only as an explicit
exception.

The existing manifests still use the legacy unqualified format during Phase 1
because the current installer consumes them directly. Phase 2 will audit every
package source, move packages to their purpose-based owner, and switch the
installer to the qualified format as one coherent change.
