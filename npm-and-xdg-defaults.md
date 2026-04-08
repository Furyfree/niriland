# `npm` Updates and XDG Editor Defaults

This note covers two separate things that look similar at first glance but are configured through different mechanisms:

- updating globally installed npm CLIs like Codex and Claude
- choosing a preferred terminal vs a preferred code editor on a Niri desktop

## `npm` Update Behavior

`npm` does have an update command, but it is not exactly the same shape as `cargo update`.

Useful commands:

```bash
npm outdated -g
npm update -g
```

What `npm update -g` does:

- updates globally installed packages that are outdated
- respects npm semver rules
- may not jump to a new major version if the installed package/range does not allow it

If you want to force the newest release of a specific CLI, use:

```bash
npm install -g @openai/codex@latest
npm install -g @anthropic-ai/claude-code@latest
```

If you only want to inspect what would change first:

```bash
npm outdated -g
```

Short version:

- `cargo update` mostly refreshes dependency resolution inside a Rust project lockfile
- `npm update -g` updates globally installed CLI packages
- `npm install -g <pkg>@latest` is the direct way to jump to the latest published version

## Terminal Preference vs Editor Preference

These are not the same layer.

### Terminal Preference

The file:

```text
~/.config/niri-xdg-terminals.list
```

is for preferred terminal selection in the Niri/DMS flow.

Example:

```text
com.mitchellh.ghostty.desktop
```

That file is the right place for "which terminal should open".

### Editor / File-Open Preference

The preferred editor for file types is usually resolved through XDG MIME associations, typically from:

```text
~/.config/mimeapps.list
```

That is where associations like these belong:

- `text/markdown`
- `text/x-python`
- `application/json`
- `text/x-shellscript`

If a code-oriented app is showing VSCodium as the preferred editor, the first thing to check is usually:

```bash
xdg-mime query default text/markdown
xdg-mime query default text/x-python
xdg-mime query default application/json
```

If those return `vscodium-wayland.desktop`, then the system is doing what the XDG defaults currently say.

## Does This Need Another One-Off Config File?

Usually no.

For editor/file associations, `mimeapps.list` is the normal place. There is generally no need to create a separate "preferred editor" file just because there is already a separate `niri-xdg-terminals.list` for terminals.

The terminal case is special because terminal selection is often handled by launcher/session glue rather than normal MIME associations.

## Important Zed Caveat

Even if you want Zed to be the preferred code editor, that only works cleanly for MIME types that Zed's desktop entry declares.

If Zed only advertises a narrow set such as:

- `text/plain`
- `application/x-zerosize`
- `x-scheme-handler/zed`

then many code file types may still resolve to another editor that explicitly claims those MIME types, such as VSCodium.

In that case there are two parts to the fix:

1. set the defaults in `~/.config/mimeapps.list`
2. make sure the Zed `.desktop` file actually declares the code MIME types you want it to handle

Without that second part, some desktop components may continue to prefer VSCodium because its desktop entry advertises many language/file MIME types.

## Practical Recommendation

Use this split:

- terminal choice: `~/.config/niri-xdg-terminals.list`
- editor/file-type choice: `~/.config/mimeapps.list`

If Zed should replace VSCodium as the default code editor, update `mimeapps.list` for the relevant MIME types and, if needed, extend Zed's desktop entry so it claims those file types.
