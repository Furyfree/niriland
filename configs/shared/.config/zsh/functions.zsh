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

flashiso() {
    if [ $# -lt 1 ]; then
        echo "Usage: flashiso <image.iso> [device]"
        return 1
    fi

    local iso="$1"

    if [ ! -f "$iso" ]; then
        echo "Error: '$iso' not found"
        return 1
    fi

    local dev="$2"

    if [ -z "$dev" ]; then
        echo "Available removable drives:"
        echo "─────────────────────────────"
        lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E "usb|NAME"
        echo "─────────────────────────────"
        echo -n "Device (e.g. sda): "
        read dev
    fi

    # Prepend /dev/ if not already there
    [[ "$dev" != /dev/* ]] && dev="/dev/$dev"

    if [ ! -b "$dev" ]; then
        echo "Error: '$dev' is not a valid block device"
        return 1
    fi

    echo ""
    echo "This will ERASE all data on $dev"
    lsblk "$dev"
    echo ""
    echo -n "Continue? [y/N] "
    read confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo dd if="$iso" of="$dev" bs=4M status=progress oflag=sync
        echo "Done ✓"
    else
        echo "Aborted"
    fi
}