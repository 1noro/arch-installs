#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

# -- comprobaciones iniciales --------------------------------------------------
# comprobación de red DHCP (por cable)
ping archlinux.org

# activamos el servidor SSH y configuramos una contraseña para root
# por si queremos realizar la instalación de forma remota
systemctl start sshd
passwd
ip a

# verificamos que entramos en modo UEFI
ls /sys/firmware/efi/efivars

# -- ejecución de scripts ------------------------------------------------------
pacman -Syy && \
pacman -S --noconfirm --needed git && \
git clone https://github.com/1noro/arch-installs.git

cd arch-installs/computers/koi || true

bash 1-archiso-steps.sh

# -- REBOOT --------------------------------------------------------------------
# iniciamos sesión como "cosmo"
git clone https://github.com/1noro/arch-installs.git

cd arch-installs/computers/koi || true

bash 2-first-boot-steps.sh

# -- REBOOT --------------------------------------------------------------------
