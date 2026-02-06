#######################################
# HISTORY CONFIG
#######################################
HISTSIZE=10000               # number of commands kept in memory
SAVEHIST=10000               # number of commands saved to file
HISTFILE=~/.zsh_history      # history file path

setopt APPEND_HISTORY         # append to history file, don't overwrite
setopt INC_APPEND_HISTORY     # write to history immediately
setopt SHARE_HISTORY          # share history across terminals

setopt HIST_IGNORE_DUPS       # ignore duplicate of the previous command
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate commands
setopt HIST_SAVE_NO_DUPS      # don't save dups in history file
setopt HIST_EXPIRE_DUPS_FIRST # expire duplicates before unique entries

setopt HIST_FIND_NO_DUPS      # skip duplicates when searching history
setopt HIST_IGNORE_SPACE      # don't record commands starting with space
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks
setopt HIST_LEX_WORDS         # better parsing of complex/multiline commands
setopt HIST_VERIFY            # don't run recalled command immediately
