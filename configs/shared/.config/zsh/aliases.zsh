#######################################
# ALIASES
#######################################

# File and Directory Operations
alias y='yazi'
alias ls='eza --icons --grid --group-directories-first'
alias ll='eza -lah --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first'
alias la='eza -a --icons --grid --group-directories-first'
alias cat='bat -pp'
alias mkdir='mkdir -p'
alias cd='z'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# System Utilities
alias c='clear'
alias e='exit'
alias f='fastfetch'
alias help='tldr'
alias history='history 1'
alias paste="wl-paste"

copy() {
  if [[ $# -eq 1 ]]; then
    wl-copy < "$1"
  elif [[ $# -gt 1 ]]; then
    command cat -- "$@" | wl-copy
  else
    wl-copy
  fi
}

# Development Tools
alias nvimconfig="cd ~/.config/nvim && nvim ."
alias n="nvim"
alias hx='helix'
alias ld='lazydocker'
# alias zed='zeditor'
alias code='vscodium'

# Search and Find
alias fman='compgen -c | fzf | xargs man'
alias fzf-find='fd --type f | fzf'
alias find='fd'

# Package Helpers
alias npi='niriland-pkg install'
alias npr='niriland-pkg remove'
alias npu='niriland-pkg upgrade'
alias npl='niriland-pkg installed'
alias clean='niriland-pkg clean'
