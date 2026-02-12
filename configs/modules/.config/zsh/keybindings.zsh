#######################################
# KEYBINDINGS (Bash-like behavior)
#######################################

bindkey -e                               # Use emacs-style keybindings (default in Bash)

# Navigation: Home / End
bindkey '^[[H' beginning-of-line         # Home -> jump to start of line
bindkey '^[[F' end-of-line               # End  -> jump to end of line

# Navigation: PageUp / PageDown
# Disable in ZLE so terminal handles scrollback instead of history search
bindkey '^[[5~' undefined-key            # PageUp
bindkey '^[[6~' undefined-key            # PageDown

# Editing: Delete / Backspace variations
bindkey '^[[3~' delete-char              # Delete -> remove character under cursor
bindkey '^H' backward-kill-word          # Ctrl+Backspace -> delete previous word
bindkey '^[[3;5~' kill-word              # Ctrl+Delete -> delete next word

# Word-wise navigation
bindkey '^[[1;5C' forward-word           # Ctrl+Right -> jump forward one word
bindkey '^[[1;5D' backward-word          # Ctrl+Left  -> jump backward one word
