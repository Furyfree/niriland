# Aliases.

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -lh --icons --git'
  alias la='eza -lah --icons --git'
  alias lt='eza --tree --icons'
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

if command -v rg >/dev/null 2>&1; then
  alias grep='rg --color=auto'
fi

alias diff='diff --color=auto'
alias df='df -h'
alias mkdir='mkdir -p'
alias -- -='cd -'

alias y='yazi'
alias c='clear'
alias e='exit'
alias f='fastfetch'
alias help='tldr'
alias history='history 1'
alias paste='wl-paste'

alias vim='nvim'
alias n='nvim'
alias hx='helix'
alias ld='lazydocker'
alias code='vscodium'
alias nvimconfig='cd ~/.config/nvim && nvim .'

alias fman='compgen -c | fzf | xargs man'
alias fzf-find='fd --type f | fzf'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

alias npi='niriland-pkg install'
alias npr='niriland-pkg remove'
alias npu='niriland-pkg upgrade'
alias npl='niriland-pkg installed'
alias clean='niriland-pkg clean'
