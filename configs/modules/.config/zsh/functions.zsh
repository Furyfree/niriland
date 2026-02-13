#######################################
# CUSTOM FUNCTIONS
#######################################

nr() {
  if [ -n "$1" ]; then
    z "$1" || return
  fi
  n .
  z
}

zr() {
  if [ -n "$1" ]; then
    z "$1" || return
  fi
  zed .
  z
}

lg() {
  if [ -n "$1" ]; then
    z "$1" || return
  fi
  lazygit
  z
}
