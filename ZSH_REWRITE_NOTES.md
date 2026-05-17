# Zsh Rewrite Notes

Source inspiration:

- https://github.com/radleylewis/zsh
- Read at commit `252f8267d7ed3d5071232e30e3cf8bcd7e387f3f`

This is a working note for trying a cleaner Zsh setup inside Niriland first.
The structure should be close enough to move to `dotfiles` later.

## Main Idea

Use Zsh's native startup model instead of keeping a large `~/.zshrc` in `$HOME`.

The clean shape is:

- `/etc/zsh/zshenv` sets `ZDOTDIR` when `~/.config/zsh` exists.
- No Zsh startup file is required directly in `$HOME`.
- Real user config lives in `~/.config/zsh`.
- History lives in `~/.local/state/zsh/history`.
- Completion cache lives in `~/.cache/zsh/zcompdump`.
- `.zshrc` is the interactive entrypoint and sources small modules.

## System Bootstrap Detail

The video shows editing `/etc/zsh/zshenv` so the system-level Zsh startup file
sets XDG config defaults and points Zsh at `~/.config/zsh` when that directory
exists.

Equivalent shape:

```zsh
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

This means a new shell can find:

```text
~/.config/zsh/.zshenv
~/.config/zsh/.zshrc
```

without requiring a large `~/.zshenv` in `$HOME`.

For Niriland, `/etc/zsh/zshenv` should be owned as machine setup. That is the
point of this layout: there should be no Zsh config file in `$HOME`; all
user-level Zsh config should live in `~/.config/zsh`.

## Directories To Ensure

The setup needs these directories:

```sh
mkdir -p ~/.config/zsh
mkdir -p ~/.local/state/zsh
mkdir -p ~/.cache/zsh
```

In Niriland config deployment, these map to tracked files under:

```text
configs/base/.config/zsh/
```

The cache and state directories should be created by install/migration logic,
not by normal shell startup unless there is a specific reason.

## Proposed Files

Create these files in this repo:

```text
configs/system/etc/zsh/zshenv
configs/base/.config/zsh/.zshenv
configs/base/.config/zsh/.zprofile
configs/base/.config/zsh/.zshrc
configs/base/.config/zsh/aliases.zsh
configs/base/.config/zsh/bindings.zsh
configs/base/.config/zsh/completion.zsh
configs/base/.config/zsh/env.zsh
configs/base/.config/zsh/fzf.zsh
configs/base/.config/zsh/functions.zsh
configs/base/.config/zsh/history.zsh
configs/base/.config/zsh/path.zsh
configs/base/.config/zsh/plugins.zsh
configs/base/.config/zsh/prompt.zsh
configs/base/.config/zsh/zoxide.zsh
configs/base/.config/zsh/starship.toml
configs/base/.config/zsh/.gitignore
```

Existing Sheldon config can stay here for now:

```text
configs/base/.config/sheldon/plugins.toml
```

## `configs/system/etc/zsh/zshenv`

Purpose: system-level Zsh bootstrap.

This is what keeps `$HOME` free of Zsh startup files. It should only establish
XDG config and point Zsh at `~/.config/zsh` when that directory exists:

```zsh
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

Open question: whether this file should also set `XDG_CACHE_HOME`,
`XDG_DATA_HOME`, and `XDG_STATE_HOME`. Keeping only `XDG_CONFIG_HOME` here is
closer to the video and keeps `/etc` minimal. The user-level
`~/.config/zsh/.zshenv` can set the rest.

Niriland should deploy this with backup, because it is a system file:

```text
/etc/zsh/zshenv
```

Do not deploy `configs/base/.zshenv` in the final version.

## `configs/base/.config/zsh/.zshenv`

Purpose: environment that should apply to all Zsh shells, including
non-interactive shells.

Include only stable environment, not prompt/plugins/completion.

Candidate content:

```zsh
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export EDITOR="nvim"
export VISUAL="nvim"

if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

if [[ -t 0 ]]; then
  export GPG_TTY="$(tty)"
fi

export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
```

Open question: Flutter-specific values currently in `~/.zshenv` should likely
move here or to a profile-specific file:

```zsh
export CHROME_EXECUTABLE="/usr/bin/helium-browser"
```

Flutter PATH may be better in `path.zsh` or `.zprofile`, depending on whether
we want it in every shell or login shells only.

## `configs/base/.config/zsh/.zprofile`

Purpose: login-shell setup.

Candidate responsibilities:

- Add Niriland tools to PATH.
- Add JetBrains Toolbox scripts if present.
- Keep login-only environment out of `.zshrc`.

Example shape:

```zsh
path=(
  "$HOME/.local/bin"
  "$HOME/.local/bin/niriland"
  $path
)

if [[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]]; then
  path+=("$HOME/.local/share/JetBrains/Toolbox/scripts")
fi

export PATH
```

This replaces the current behavior where `scripts/install/steps/50-setup-tools`
appends to `~/.zprofile`.

## `configs/base/.config/zsh/.zshrc`

Purpose: interactive entrypoint.

It should return early for non-interactive shells:

```zsh
[[ -o interactive ]] || return
```

Recommended order:

```zsh
source "$ZDOTDIR/path.zsh"
source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/history.zsh"
source "$ZDOTDIR/zoxide.zsh"
source "$ZDOTDIR/completion.zsh"
source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/plugins.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/prompt.zsh"
```

Radley's repo keeps history, shell behavior, zoxide, completion, and fzf bootstrap
directly in `.zshrc`, then sources smaller modules. For Niriland, splitting
those into modules is cleaner because we already have several concerns.

## `history.zsh`

Use XDG state:

```zsh
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
```

Niriland currently uses `~/.zsh_history`; this should be migrated.

Migration should copy or move:

```text
~/.zsh_history -> ~/.local/state/zsh/history
```

with backup first.

## Shell Behavior

Radley's `.zshrc` enables:

```zsh
setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT
```

These are reasonable defaults for Niriland too.

Possible location:

```text
configs/base/.config/zsh/env.zsh
```

or a dedicated:

```text
configs/base/.config/zsh/options.zsh
```

For now, keep it in `env.zsh` unless the file grows too much.

## `zoxide.zsh`

Do not assume `zoxide` exists:

```zsh
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
```

Do not alias `cd` to `z` in the first clean version. Keep `z` available through
zoxide and decide later whether `cd` should be overridden.

## `completion.zsh`

Use explicit XDG compdump:

```zsh
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
```

If using `zsh-completions` through Sheldon, add its `src` directory to `fpath`
before `compinit`.

Potential Niriland-specific addition:

```zsh
if command -v op >/dev/null 2>&1; then
  eval "$(op completion zsh)"
fi
```

But this should be checked because current 1Password setup tried to write cache
files during shell startup in the sandbox.

## Fzf Bootstrap In `.zshrc`

Radley's setup checks common fzf install paths:

```text
/opt/homebrew/opt/fzf/shell/key-bindings.zsh
/usr/local/opt/fzf/shell/key-bindings.zsh
/usr/share/fzf/key-bindings.zsh
/usr/share/doc/fzf/examples/key-bindings.zsh
```

Niriland should support Arch first, but the portable path checks are fine if we
want the same config to move to dotfiles later.

Alternative: use `source <(fzf --zsh)` when `fzf` supports it. The current
Niriland config does this, but it is less explicit about platform paths.

## `fzf.zsh`

Radley's fzf config sets:

- `FZF_DEFAULT_COMMAND` to use `fd`.
- `FZF_CTRL_T_COMMAND` from the same command.
- compact fzf UI options.
- preview through `bat`.
- a custom Ctrl-F widget for file search without hidden files.

Niriland version should guard `fd`, `fdfind`, `bat`, and `batcat`:

```zsh
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
elif command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --strip-cwd-prefix'
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS='
  --height=40%
  --layout=reverse
  --border
'
```

If we use preview:

```zsh
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"
elif command -v batcat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'batcat --style=numbers --color=always {}'"
fi
```

Ctrl-F widget shape:

```zsh
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf) && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _fzf_file_no_hidden
```

## `aliases.zsh`

Radley keeps aliases focused and guards Ubuntu command-name differences.

Niriland should do the same:

```zsh
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -lh --icons --git'
  alias la='eza -lah --icons --git'
  alias tree='eza --tree --icons'
  compdef eza=ls
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat='batcat'
fi

if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'
alias -- -='cd -'
alias vim='nvim'
```

Open question: current Niriland aliases like these are convenient but less
clean:

```zsh
alias cd='z'
alias find='fd'
alias cat='bat -pp'
```

Recommendation: do not carry those over in the first clean version.

## `plugins.zsh`

Radley uses a tiny custom plugin loader:

- plugin directory: `$ZDOTDIR/plugins`
- clone missing plugins on first launch
- source each plugin's `.plugin.zsh`
- expose `zplugin-update` to pull updates

Plugin list in the repo:

```text
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search
jeffreytse/zsh-vi-mode
```

For Niriland first iteration, prefer keeping Sheldon because we already package
and configure it.

Sheldon keeps plugin management declarative:

```text
configs/base/.config/sheldon/plugins.toml
```

Current Niriland Sheldon plugins:

```text
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-completions
Aloxaf/fzf-tab
MichaelAquilina/zsh-you-should-use
ohmyzsh/ohmyzsh lib/git
ohmyzsh/ohmyzsh plugins/git
ohmyzsh/ohmyzsh plugins/1password
```

Decision to make later:

- Keep Sheldon.
- Replace Sheldon with a tiny loader.
- Keep Sheldon for now, then migrate after layout is stable.

Recommendation: keep Sheldon for now.

## `bindings.zsh`

If we keep Niriland's current Emacs-style bindings, use direct `bindkey`.

If we adopt `zsh-vi-mode`, custom bindings need to be registered through the
plugin hook because `zsh-vi-mode` resets keybindings during init.

Radley-style vi-mode settings:

```zsh
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none
```

Hook shape:

```zsh
zvm_after_init() {
  bindkey '^[[1;5C' forward-word
  bindkey '^[[1;5D' backward-word
  bindkey '^F' _fzf_file_no_hidden
  bindkey '^\' autosuggest-toggle
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}
```

Open question: Niriland currently uses Bash-like/Emacs bindings. Moving to
vi-mode changes muscle memory, so this should be an explicit decision.

## `prompt.zsh`

Keep prompt initialization separate:

```zsh
export VIRTUAL_ENV_DISABLE_PROMPT=1

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

`STARSHIP_CONFIG` should be set in `.zshenv`:

```zsh
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
```

## `starship.toml`

Radley includes `starship.toml` directly in the Zsh config directory.

For Niriland:

```text
configs/base/.config/zsh/starship.toml
```

This is cleaner than depending on:

```text
~/.config/starship/starship.toml
```

unless we want Starship to remain a separate app config.

Open question: should prompt theme belong to Zsh config or global Starship
config? Radley's layout puts it with Zsh. Current Niriland uses separate
Starship config.

## `.gitignore` Under Zsh Config

Useful ignore patterns if this config is later moved into a standalone dotfiles
repo or symlinked:

```gitignore
*.zwc
.zcompdump*
plugins/
local.zsh
.DS_Store
```

Inside Niriland's `configs/base/.config/zsh`, this may be less useful because
generated files should never be written there. Still okay as documentation.

## Niriland Changes Needed Later

Current files that conflict with the clean model:

```text
configs/base/.zshrc
configs/modules/.config/zsh/*
scripts/install/steps/50-setup-tools
scripts/tools/niriland-setup-flutter
scripts/install/steps/40-setup-shell
```

What should change:

- Deploy `configs/system/etc/zsh/zshenv` to `/etc/zsh/zshenv` with backup.
- Stop deploying any Zsh startup file directly into `$HOME`.
- Stop deploying root `~/.zshrc`.
- Stop using `~/.local/share/niriland/configs/modules/.config/zsh` as runtime config.
- Stop appending PATH to `~/.zprofile` from `50-setup-tools`.
- Stop appending Flutter values to `~/.zshenv` from `niriland-setup-flutter`.
- Add migration/backups for `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, and `~/.zsh_history`.
- Create `~/.local/state/zsh` and `~/.cache/zsh`.

## First Implementation Pass

Recommended order:

1. Add the new files under `configs/base/.config/zsh`.
2. Add `configs/system/etc/zsh/zshenv`.
3. Move current module contents into the new layout, with guards around commands.
4. Change history and compdump to XDG paths.
5. Keep Sheldon.
6. Update `40-setup-shell` to install/deploy `/etc/zsh/zshenv`.
7. Add a migration note for existing installs.
8. After testing, remove or deprecate old `configs/modules/.config/zsh`.

## Decisions Still Open

- How much should `/etc/zsh/zshenv` do beyond setting `XDG_CONFIG_HOME` and `ZDOTDIR`?
- Should we keep Sheldon or move to a tiny custom plugin loader?
- Should the shell use vi-mode or keep current Emacs/Bash-like bindings?
- Should `starship.toml` live under `~/.config/zsh` or `~/.config/starship`?
- Should Flutter PATH be global, login-only, or profile-specific?
- Should aggressive aliases like `cd='z'`, `find='fd'`, and `cat='bat -pp'` be kept?
