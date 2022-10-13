#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

# -- ejecución de scripts ------------------------------------------------------
# script base
bash archiso-base.sh

# -- copiamos el siguiente script y el .env a la carpeta correspondiente
cp .env /mnt/tmp/
cp archiso-chroot.sh /mnt/tmp/

# script chroot
arch-chroot /mnt bash /tmp/archiso-chroot.sh

# -- pasos finales -------------------------------------------------------------
# desmontamos con seguridad el entorno de instalación
sync && umount -R /mnt

# reiniciamos
# reboot
