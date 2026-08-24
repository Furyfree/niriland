# Custom functions.

copy() {
  if ! command -v wl-copy >/dev/null 2>&1; then
    echo "copy: wl-copy is not installed" >&2
    return 1
  fi

  if [[ $# -eq 1 ]]; then
    wl-copy < "$1"
  elif [[ $# -gt 1 ]]; then
    command cat -- "$@" | wl-copy
  else
    wl-copy
  fi
}

nr() {
  if [[ -n "${1:-}" ]]; then
    z "$1" || return
  fi
  n .
  z
}

zr() {
  if [[ -n "${1:-}" ]]; then
    z "$1" || return
  fi
  zed .
  z
}

lg() {
  if [[ -n "${1:-}" ]]; then
    z "$1" || return
  fi
  lazygit
  z
}

flashiso() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: flashiso <image.iso> [device]" >&2
    return 1
  fi

  local iso="$1"
  local dev="${2:-}"

  if [[ ! -f "$iso" ]]; then
    echo "flashiso: '$iso' not found" >&2
    return 1
  fi

  if [[ -z "$dev" ]]; then
    echo "Available removable drives:"
    lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E 'usb|NAME'
    printf 'Device (e.g. sda): '
    read -r dev
  fi

  [[ "$dev" != /dev/* ]] && dev="/dev/$dev"

  if [[ ! -b "$dev" ]]; then
    echo "flashiso: '$dev' is not a valid block device" >&2
    return 1
  fi

  echo "This will erase all data on $dev"
  lsblk "$dev"
  printf 'Continue? [y/N] '
  read -r confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo dd if="$iso" of="$dev" bs=4M status=progress oflag=sync
  else
    echo "Aborted"
  fi
}
