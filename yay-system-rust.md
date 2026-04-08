# Using System Rust for `yay` and `paru` Builds

The clean way is to scope this to Arch package builds, not your whole shell.

## Original Build Failure

From the `lib32-gstreamer` build:

```text
gstreamer| Dependency glib-2.0 found: YES 2.88.0 (cached)
gstreamer| Program /usr/bin/glib-mkenums found: YES (/usr/bin/glib-mkenums)
gstreamer| Dependency glib-2.0 found: YES 2.88.0 (cached)
gstreamer| Program /usr/bin/glib-mkenums found: YES (/usr/bin/glib-mkenums)
gstreamer| Compiler for language rust for the host machine not found.

gstreamer/subprojects/gstreamer/libs/gst/helpers/ptp/meson.build:26:4: ERROR: Problem encountered: PTP not supported without Rust compiler

A full log can be found at /home/pby/.cache/yay/lib32-gstreamer/src/build/meson-logs/meson-log.txt
==> ERROR: A failure occurred in build().
    Aborting...
 -> error making: lib32-gstreamer-exit status 4
 -> nothing to install for lib32-gstreamer
 -> Failed to install the following packages. Manual intervention is required:
lib32-gstreamer - exit status 4
```

## What The Debugging Showed

This is not a "Rust is too old" problem.

The build is using the `rustup` toolchain from `~/.cargo/bin`, not the packaged system Rust in `/usr/bin`.

Relevant environment and command output:

```text
$ command -v rustc
/home/pby/.cargo/bin/rustc

$ rustc --print sysroot
/home/pby/.rustup/toolchains/stable-x86_64-unknown-linux-gnu

$ rustc --print target-libdir --target i686-unknown-linux-gnu
/home/pby/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/i686-unknown-linux-gnu/lib

$ env | rg '^(RUST|CARGO)'
CARGO_HOME=/home/pby/.cargo
RUSTUP_HOME=/home/pby/.rustup
RUSTUP_TOOLCHAIN=stable
```

The important Meson log entry is:

```text
Called: `rustc --target i686-unknown-linux-gnu -C linker=gcc -C link-arg=-m32 -o /home/pby/.cache/yay/lib32-gstreamer/src/build/meson-private/rusttest.exe /home/pby/.cache/yay/lib32-gstreamer/src/build/meson-private/sanity.rs` -> 1
stderr:
error[E0463]: can't find crate for `std`
  |
  = note: the `i686-unknown-linux-gnu` target may not be installed
  = help: consider downloading the target with `rustup target add i686-unknown-linux-gnu`

error: aborting due to 1 previous error
```

So Meson says "Compiler for language rust for the host machine not found", but the real issue is narrower: `rustc` is present, but the `rustup` toolchain cannot find the 32-bit target standard library.

## Package Context

Package state at the time of debugging:

```text
$ pacman -Q rust cargo
rust 1:1.94.1-1.1
rust 1:1.94.1-1.1

$ pacman -Q lib32-rust
lib32-rust-libs 1:1.94.1-1.1

$ pacman -Q lib32-gstreamer
lib32-gstreamer 1.28.1-2
```

The cached `lib32-gstreamer` packaging data shows that the package expects 32-bit Rust support at build time:

```text
makedepends=(
  ...
  lib32-rust
  ...
)
```

And the repository metadata for `lib32-rust-libs` shows:

```text
Name            : lib32-rust-libs
Provides        : lib32-rust
Depends On      : lib32-gcc-libs  lib32-glibc  rust
Conflicts With  : lib32-rust
Replaces        : lib32-rust
```

That means the packaged system Rust stack is already designed to satisfy this. The failure happens because the build picks up the user-local `rustup` compiler first.

## System Rust Check

The packaged Rust compiler is present and points at the correct sysroot:

```text
$ /usr/bin/rustc --version
rustc 1.94.1 (e408947bf 2026-03-25) (Arch Linux rust 1:1.94.1-1.1)

$ /usr/bin/rustc --print sysroot
/usr

$ /usr/bin/rustc --print target-libdir --target i686-unknown-linux-gnu
/usr/lib/rustlib/i686-unknown-linux-gnu/lib
```

This is why making the AUR helper prefer `/usr/bin` fixes the package build.

## Local Helper State

On this system at the time of debugging:

```text
$ pacman -Q yay paru
yay 12.5.7-1
paru 2.1.0-2

$ command -v yay paru
/usr/bin/yay
/usr/bin/paru
```

That means the helper binaries themselves are packaged system binaries. The problem was not `yay` being installed from Cargo or from `rustup`; the problem was the build environment finding `~/.cargo/bin/rustc` before `/usr/bin/rustc`.

## Option 1: Add a dedicated shell function

Add this to `~/.zshrc`:

```zsh
yay-system() {
  env PATH=/usr/bin:/bin:/usr/sbin:/sbin "$HOME/.cargo/bin/yay" "$@"
}
```

Then use:

```bash
yay-system -S lib32-gstreamer
```

`yay-system` is not a package. It is just a shell function name chosen in this example.

## Option 2: Alias `yay` to prefer system tools

Add this to `~/.zshrc`:

```zsh
alias yay='env PATH=/usr/bin:/bin:/usr/sbin:/sbin yay'
```

This makes package builds prefer `/usr/bin/rustc`, while normal Rust project work can still use `rustup` in shells where you bypass the alias.

In this version, `yay` is still the `yay` package. The alias only changes how your shell expands the command.

## Option 3: Use a wrapper script

Create a small script such as `~/bin/yay-system`:

```bash
#!/bin/sh
exec env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/yay "$@"
```

In this version, `yay-system` is a wrapper script that you create yourself. It is still not a package.

## The Same Approach With `paru`

Yes. The same `PATH` override works with `paru`.

Direct command:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin paru -S lib32-gstreamer
```

You could also define a matching shell function:

```zsh
paru-system() {
  env PATH=/usr/bin:/bin:/usr/sbin:/sbin /usr/bin/paru "$@"
}
```

Or an alias:

```zsh
alias paru='env PATH=/usr/bin:/bin:/usr/sbin:/sbin paru'
```

## Recommendation

Use option 1. It is explicit, easy to undo, and avoids interfering with project-local `rustup` usage.

If you prefer to keep using `rustup` for package builds, the other valid fix is:

```bash
rustup target add i686-unknown-linux-gnu
yay -S lib32-gstreamer
```

That works too, but it is less aligned with how Arch package builds expect toolchains to come from the system.

## `paru` vs `yay` for Updates

Short version:

- If you want one helper for routine updates with the least surprise, I would currently lean slightly toward `paru`.
- If you already use `yay` and it is working well for you, there is no urgent reason to switch.

Why I lean toward `paru`:

- `paru` had an explicit pacman 7 support release in `v2.0.4` on `2024-09-20`.
- The latest `paru` release visible from upstream is `v2.1.0` on `2025-07-08`, and it includes multiple update/build/chroot fixes.
- `yay` is also active and its upstream repo shows CI for both pacman and pacman-git, so it is not abandoned or obviously unstable.

Recommendation:

- For routine `-Syu` usage, standardize on `paru` if you want the more conservative choice today.
- Keep using `yay` if you prefer its interface or already have muscle memory around it.
- Do not mix helpers casually for the same maintenance workflow unless you understand their caches and devel-package tracking behavior.

This recommendation is an inference from current upstream activity and release notes, not an official Arch Linux endorsement. Arch does not officially support AUR helpers.

## Is This Recommended For System Upgrades?

Yes, with an important scope limit: this is reasonable for `yay` or `paru` runs, but it is not something to apply blindly to the whole login environment.

Recommended approach:

- For normal repository-only upgrades, use `pacman` normally.
- For `yay` or `paru` upgrades that may build AUR packages, using `env PATH=/usr/bin:/bin:/usr/sbin:/sbin ...` is a good defensive choice on this system.
- Do not permanently remove `~/.cargo/bin` from your global `PATH` unless you want to stop defaulting to `rustup` for development work.

Practical examples:

```bash
sudo pacman -Syu
env PATH=/usr/bin:/bin:/usr/sbin:/sbin paru -Syu
env PATH=/usr/bin:/bin:/usr/sbin:/sbin yay -Syu
```

Why:

- It prevents package builds from accidentally picking `rustup` shims instead of distro toolchains.
- Arch package builds generally behave more predictably with system compilers and system toolchains.
- It avoids disrupting normal Rust project workflows that intentionally rely on `rustup`.

Conclusion:

- Recommended for helper-driven upgrades on this machine: yes.
- Recommended as a permanent global shell rule for everything: no.

## Confirmed Working Command

This command worked:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin yay
```

For the package install case, use the same approach with arguments, for example:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin yay -S lib32-gstreamer
```

This works because it makes `yay` and the package build process prefer `/usr/bin/rustc` over `~/.cargo/bin/rustc`.

The matching `paru` form is:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin paru
```

## Verification

Run:

```bash
yay-system -S lib32-gstreamer
```

If you need to verify which Rust toolchain is being used:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin rustc --print sysroot
```

That should print:

```text
/usr
```

## Sources Used For The `paru` vs `yay` Recommendation

- `paru` upstream releases: <https://github.com/Morganamilo/paru/releases>
- `paru` README: <https://github.com/Morganamilo/paru>
- `yay` upstream README and activity: <https://github.com/Jguer/yay>
- `yay` CI page: <https://github.com/Jguer/yay/actions>
