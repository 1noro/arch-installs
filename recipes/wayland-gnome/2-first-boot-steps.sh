#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

# -- CONFIGURACION DEL GRUB ----------------------------------------------------
# (se puede mover al archiso-chroot.sh)
sudo cp arch-installs/misc/grub-bg.png /boot/grub/grub-bg.png
# sudo nvim /etc/default/grub
# descomentamos y editamos las lineas:
# GRUB_BACKGROUND="/boot/grub/grub-bg.png"
# #GRUB_GFXMODE=1920x1080x32
# #GRUB_GFXMODE=2560x1440x32
# GRUB_GFXMODE=auto
# GRUB_GFXPAYLOAD_LINUX=keep
# - lo que hacemos es añadir las lineas al final del fichero
{
    echo 'GRUB_BACKGROUND="/boot/grub/grub-bg.png"'
    echo "GRUB_GFXMODE=auto"
    echo "RUB_GFXPAYLOAD_LINUX=keep"
} >> /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# instalamos los paquetes habituales
sudo bash arch-installs/packages/install-official-basic.sh
sudo bash arch-installs/packages/install-official-extra.sh
bash arch-installs/packages/install-aur.sh
sudo bash arch-installs/packages/remove.sh

# borramos este repositorio
rm -rf arch-installs

# reiniciamos
# sudo reboot
