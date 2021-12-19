#!/bin/bash
# koi FIRSTBOOT

# iniciamos sesión como "cosmo"
git clone https://github.com/1noro/arch-installs.git
bash arch-installs/computers/koi/first-boot.sh

# -- CONFIGURACION DEL GRUB ----------------------------------------------------
# (se puede mover al archiso-chroot.sh)
sudo cp arch-installs/misc/grub-bg.png /boot/grub/grub-bg.png
sudo nvim /etc/default/grub
# descomentamos y editamos las lineas:
# GRUB_BACKGROUND="/boot/grub/grub-bg.png"
# #GRUB_GFXMODE=1920x1080x32
# #GRUB_GFXMODE=2560x1440x32
# GRUB_GFXMODE=auto
# GRUB_GFXPAYLOAD_LINUX=keep
sudo grub-mkconfig -o /boot/grub/grub.cfg

# instalamos los paquetes habituales
sudo bash arch-installs/packages/install-official-basic.sh
sudo bash arch-installs/packages/install-official-extra.sh
sudo bash arch-installs/packages/install-aur.sh
sudo bash arch-installs/packages/remove.sh

# borramos este repositorio
rm -rf arch-installs

# reiniciamos
sudo reboot
