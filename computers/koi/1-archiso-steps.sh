#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

# -- ejecución de scripts ------------------------------------------------------
# script base
bash archiso-base.sh

# -- copiamos el siguiente script y el .env a la carpeta correspondiente
cp .env /mnt/opt/
cp archiso-chroot.sh /mnt/opt/

# script chroot
arch-chroot /mnt bash /opt/archiso-chroot.sh

rm /mnt/opt/.env /mnt/opt/archiso-chroot.sh

# -- pasos finales -------------------------------------------------------------
# desmontamos con seguridad el entorno de instalación
sync && umount -R /mnt

# reiniciamos
# reboot
