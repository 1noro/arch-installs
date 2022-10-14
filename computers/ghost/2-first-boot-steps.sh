#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

# -- ejecución de scripts ------------------------------------------------------
echo -e "\e[92m\e[1m>>> BEGIN first-boot.sh\e[0m"
bash first-boot.sh
echo -e "\e[92m\e[1m<<< END first-boot.sh\e[0m"

# -- CONFIGURACION DEL GRUB ----------------------------------------------------
# (se puede mover al archiso-chroot.sh)
# TODO: automatizar
# sudo cp ../../misc/grub-bg.png /boot/grub/grub-bg.png
# sudo nvim /etc/default/grub
# # descomentamos y editamos las lineas:
# # GRUB_BACKGROUND="/boot/grub/grub-bg.png"
# # #GRUB_GFXMODE=1920x1080x32
# # #GRUB_GFXMODE=2560x1440x32
# # GRUB_GFXMODE=auto
# # GRUB_GFXPAYLOAD_LINUX=keep
# sudo grub-mkconfig -o /boot/grub/grub.cfg

# instalamos los paquetes habituales
# sudo bash ../../packages/install-official-basic.sh
# sudo bash ../../packages/install-official-extra.sh
# bash ../../packages/install-aur.sh
# sudo bash ../../packages/remove.sh
