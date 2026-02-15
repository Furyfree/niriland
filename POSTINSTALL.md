# PBY's Postinstall Checklist

Manual setup after running Niriland (`bootstrap` or `./install`).

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

1. **1Password** — password manager integration.
2. **uBlock Origin** — ad/tracker blocker.
3. **Dark Reader** — universal dark mode. Set default to **off** for new websites.
4. **Bookmarkhub** — centralized bookmark management (credentials stored in 1Password).

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

#### Flags (`helium://flags/`)

- Omnibox Autocomplete Filtering: **Search suggestions, bookmarks, and internal chrome pages**.

#### Start Page Customization

- Toolbar: Only Extensions and Main Menu enabled.
- Show Shortcuts: Disabled.

---

## Optional Tools

Run these after install as needed:

```bash
niriland-setup-ai setup
niriland-setup-certificates setup
niriland-setup-fingerprint          # laptop only
niriland-setup-gaming setup
```

---

## WoW Addon Setup

Requires WoW to be installed first.

1. Get WoWUp addon credentials from 1Password.
2. Import addons into WoWUp.

---

## JetBrains Setup

Install IDEs via JetBrains Toolbox: **IntelliJ**, **GoLand**, **PyCharm**, **CLion**, **Rider**.

Toolbox configuration:

1. Launch JetBrains Toolbox after install.
2. Log in with your JetBrains account.
3. Enable Settings Sync for automatic configuration sharing.

---

## VPN Configuration

### WireGuard (Unifi)

1. Go to Unifi Console -> Settings -> VPN -> VPN Server -> Byrne VPN WireGuard.
2. Add a new client, name it `home`, and download the config.
3. Import into NetworkManager:

```bash
nmcli connection import type wireguard file ~/Downloads/home.conf
```

4. Rename the connection:

```bash
nmcli connection modify home connection.id "unifi-wg"
```

Alternatively, import via DankMaterialShell Settings -> VPN.

Usage:

```bash
nmcli connection up unifi-wg
nmcli connection down unifi-wg
```

### DTU VPN

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

## Limine (If Dualboot)

If dual-booting with Windows, add the Windows EFI entry to Limine:

```bash
sudo limine-scan
```

Select the Windows Boot Manager entry (typically option 1).
