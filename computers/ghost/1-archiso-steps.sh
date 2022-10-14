#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

# -- ejecución de scripts ------------------------------------------------------
# script base
echo -e "\e[92m\e[1m>>> BEGIN archiso-base.sh\e[0m"
bash archiso-base.sh
echo -e "\e[92m\e[1m<<< END archiso-base.sh\e[0m"

# -- copiamos el siguiente script y el .env a la carpeta correspondiente
cp .env /mnt/opt/
cp archiso-chroot.sh /mnt/opt/

# script chroot
echo -e "\e[92m\e[1m>>> BEGIN archiso-chroot.sh in arch-chroot mode\e[0m"
arch-chroot /mnt bash /opt/archiso-chroot.sh
echo -e "\e[92m\e[1m<<< END archiso-chroot.sh in arch-chroot mode\e[0m"

rm  /mnt/opt/.env \
    /mnt/opt/archiso-chroot.sh

# -- pasos finales -------------------------------------------------------------
# desmontamos con seguridad el entorno de instalación
sync && \
umount -R /mnt
