# PBY's Postinstall Guide

Post-install checklist after running Niriland (`bootstrap` or `./install`).
This covers manual setup that is intentionally not fully automated.

---

## Repo Setup

Switch repo remote to SSH and create the `~/git` shortcut:

```bash
git -C ~/.local/share/niriland remote set-url origin git@github.com:Furyfree/niriland.git
ln -sfn ~/.local/share/niriland ~/git
```

---

## Browser Configuration

### Helium Browser Extensions
- 1Password: Password manager integration.
- uBlock Origin: Ad/tracker blocker.
- Dark Reader: Universal dark mode.
- Bookmarkhub: Centralized bookmark management (credentials stored in 1Password).

### Helium Preferences

#### Search
- Default Search Engine: Google.
- Suggestions from Search Engine: Disabled.

#### Appearance
- Theme: Helium Colors.
- Mode: Device.
- Show Home Button: Disabled.
- Show Bookmarks Bar: Disabled.
- Open New Tabs Next to Active Tab: Disabled.
- Show Tab Groups in Bookmarks Bar: Disabled.
- Automatically Pin New Tab Groups: Enabled.
- Side Panel Position: Right.
- Tab Preview Images: Enabled.
- Tab Memory Usage: Enabled.
- Use System Title Bar and Borders: Enabled.

#### Languages and Spell Check
- Preferred Languages:
  - English (United States)
  - English
  - Danish
- Spell Check Enabled For:
  - English (United States)
  - Danish

#### Start Page Customization
- Toolbar: Only Extensions and Main Menu enabled.
- Show Shortcuts: Disabled.

---

## JetBrains Setup

Toolbox configuration:
- Launch JetBrains Toolbox after install.
- Log in with your JetBrains account.
- Enable Settings Sync for automatic configuration sharing.

---

## Limine (If Dualboot)

If dual-booting with Windows, add the Windows EFI entry to Limine:

```bash
sudo limine-scan
```

Select the Windows Boot Manager entry (typically option 1).

---

## VPN Configuration

### Proton VPN

Log in and set preferences manually in the app.

### WireGuard (Unifi)

1. Go to Unifi Console -> Settings -> VPN -> VPN Server -> Byrne VPN WireGuard.
2. Add a new client and download config.
3. Import into NetworkManager:

```bash
nmcli connection import type wireguard file ~/Downloads/wg0.conf
```

4. Rename the connection:

```bash
nmcli connection modify wg0 connection.id "unifi-wg"
```

Usage:

```bash
nmcli connection up unifi-wg
nmcli connection down unifi-wg
```

### DTU VPN Setup

```bash
nmcli connection add type vpn vpn-type openconnect con-name dtu-vpn +vpn.data "gateway=vpn.dtu.dk,protocol=anyconnect"
```

Set User Agent to `AnyConnect` in NetworkManager UI.

Usage:

```bash
nmcli connection up dtu-vpn
nmcli connection down dtu-vpn
```

---

System ready - enjoy your Niriland setup.
