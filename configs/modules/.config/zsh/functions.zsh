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

# Arch clean
clean() {
  echo "==> Cleaning pacman cache"
  sudo pacman -Sc --noconfirm

  echo "==> Checking for orphan packages"
  orphans=$(sudo pacman -Qtdq 2>/dev/null)
  if [ -n "$orphans" ]; then
    echo "==> Removing orphan packages"
    sudo pacman -Rns --noconfirm $orphans
  else
    echo "--> No orphan packages found"
  fi

  echo "==> Cleaning paru cache"
  paru -Sc --noconfirm
  rm -rf ~/.cache/paru/build

  echo "==> Cleaning yay cache"
  yay -Sc --noconfirm
  rm -rf ~/.cache/yay/build

  echo "System cleaned"
}
