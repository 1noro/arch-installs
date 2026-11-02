#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

if [[ $(id -u) -eq 0 ]]; then
    echo "This script must be run as a non-root user"
    exit 1
fi

source .env


# --- start Virtual Box specific configs ---------------------------------------

# --- finish Virtual Box specific configs --------------------------------------
