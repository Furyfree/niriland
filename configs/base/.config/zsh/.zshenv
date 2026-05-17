# ~/.config/zsh/.zshenv

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"

if [[ -t 0 ]]; then
  export GPG_TTY="$(tty)"
fi

export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/helium-browser}"

if command -v bat >/dev/null 2>&1; then
  export MANPAGER="${MANPAGER:-bat -l man -p}"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="${MANPAGER:-batcat -l man -p}"
fi
