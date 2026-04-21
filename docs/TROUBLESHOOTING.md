# Troubleshooting

Known issues and practical fixes for operating a Niriland setup.

## Missing Commands Or Incomplete Setup

If expected commands are missing, verify these foundational steps completed successfully:

- `00-setup-pacman` for package-manager setup, AUR helper setup, and repo normalization
- `10-install-packages` for the main package manifests
- `50-setup-tools` for helper scripts copied into `~/.local/bin/niriland`

## AI Tooling Issues

If the AI helper stack is not working as expected:

- Run `niriland-setup-ai status`
- Verify `ollama`, `docker.service`, and `openwebui` are active
- Check the service templates under `configs/system/etc/systemd/system/`

## Ghostty Theme Issues

Ghostty will not apply the expected theme setup cleanly until a background image is configured.

- Preinstalled wallpapers are available in `~/Pictures/Wallpapers`
- In DMS: click the clock, open Wallpapers, press the folder icon, and point it at `~/Pictures/Wallpapers`
- Once that folder is registered, later wallpaper changes can reuse the same source directory

## AUR Builds Picking `rustup` Instead Of System Rust

If a `yay` or `paru` build fails because Meson or Rust cannot find the right target libraries, the build may be picking `~/.cargo/bin/rustc` instead of `/usr/bin/rustc`.

Use the helper with a system-first PATH for that build:

```bash
env PATH=/usr/bin:/bin:/usr/sbin:/sbin yay -S <package>
env PATH=/usr/bin:/bin:/usr/sbin:/sbin paru -S <package>
```

This keeps Arch package builds on the packaged Rust toolchain instead of the user-local `rustup` toolchain.
