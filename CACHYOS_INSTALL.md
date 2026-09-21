# CachyOS Install Guide For Niriland

This guide is the install baseline for a fresh Niriland target. It states the choices that matter for getting to a good Niriland base system without a preinstalled desktop environment.

The goal is a clean CachyOS install with no desktop environment preinstalled, so Niriland can layer its own session, packages, and config on top afterwards.

## What This Install Should Be

- Fresh CachyOS install
- `No Desktop`
- `Limine` bootloader
- `Btrfs`
- Optional `LUKS2` encryption
- A minimal base with CachyOS core packages enabled

Encryption is recommended, not required. If you use LUKS2 on the root filesystem, Niriland's `05-setup-fde` step can later add TPM2 auto-unlock and a recovery key when the hardware supports it.

## Before You Start

- Back up anything important.
- Boot the CachyOS USB in UEFI mode.
- Open the CachyOS installer from the live session.
- If you plan to use `Erase disk`, make sure you are targeting the correct drive.

## Install Choices

### Welcome

Start the installer and continue.

### Location

Choose the region, timezone, language, and locale you actually want for the machine.

Values such as Copenhagen, English (Denmark), and Danish locale are valid examples, but they are not Niriland requirements.

### Keyboard

Choose the keyboard layout you actually use and verify it in the test field before continuing.

`Generic 105-key PC` with `Danish` and `Default` is one valid example, but it is not a Niriland requirement.

### Bootloader

Choose:

- `Limine`

### Partitions

Choose:

- your target drive
- `GPT`
- `Erase disk`
- `btrfs`

Optional but recommended:

- `Encrypt system`

If you enable encryption:

- use `LUKS2`
- enter the encryption password carefully

Important:

- `Erase disk` wipes the selected drive.
- Choose the correct drive for your machine.

### Desktop

Choose:

- `No Desktop`

This keeps the installed system lean and leaves the desktop/session layer for Niriland to install afterwards.

### Packages

Make sure these are checked:

- `CachyOS Packages`
- `Base-devel + Common packages`

Recommended for convenience:

- `Printing-Support`
- `Support for HP Printer/Scanner`

Other things may already be checked in the installer. Leave them unchecked unless you specifically want them.

### Users

Fill in your own values for:

- full name
- username
- computer name
- password

Recommended:

- `Use the same password for the administrator account`

Replace the user, hostname, and password values with your own.

### Summary

Before clicking install, confirm:

- the timezone and locale match what you want
- the keyboard layout matches what you use
- the selected disk is correct
- the filesystem is `btrfs`
- the bootloader is `Limine`
- the desktop choice is `No Desktop`
- encryption is enabled if you want the later Niriland auto-unlock flow

### Install

Click `Install` only after checking the summary carefully, then wait for the installation to finish and reboot.

## What You End Up With

After install, you should have:

- a clean CachyOS base system
- `Limine` as bootloader
- `Btrfs`
- optional `LUKS2` encryption
- no desktop environment preinstalled
- CachyOS core packages enabled
- a system ready for Niriland to layer its own desktop/session setup on top

## Next Step

Boot into the installed system, open a terminal, and run the command from [README.md](README.md):

```bash
curl -fsSL https://raw.githubusercontent.com/Furyfree/niriland/main/bootstrap | bash
```

Or if you already cloned the repo:

```bash
~/.local/share/niriland/install
```
