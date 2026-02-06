#######################################
# ALIASES
#######################################

# File and Directory Operations
alias y='yazi'
alias ls='eza --icons --grid --group-directories-first'
alias ll='eza -lah --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first'
alias la='eza -a --icons --grid --group-directories-first'
alias cat='bat'
alias mkdir='mkdir -p'
alias cd='z'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# System Utilities
alias c='clear'
alias e='exit'
alias f='fastfetch'
alias help='tldr'
alias copy="wl-copy"
alias paste="wl-paste"

# Development Tools
alias nvimconfig="cd ~/.config/nvim && nvim ."
alias n="nvim"
alias ld='lazydocker'

# Search and Find
alias fman='compgen -c | fzf | xargs man'
alias fzf-find='fd --type f | fzf'
alias find='fd'

# Network/VPN
# DTU VPN
alias vpn-dtu-up='nmcli connection up dtu-vpn'
alias vpn-dtu-down='nmcli connection down dtu-vpn'

# Own VPN
alias vpn-up='nmcli connection up unifi-wg'
alias vpn-down='nmcli connection down unifi-wg'

# System Maintenance
alias updategrub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# AUR Helpers
alias yay='paru'