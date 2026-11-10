#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

# -- comprobaciones iniciales en archiso ---------------------------------------
# comprobación de red DHCP (por cable)
ping archlinux.org

# activamos el servidor SSH y configuramos una contraseña para root
# por si queremos realizar la instalación de forma remota
systemctl start sshd
passwd
ip a

# verificamos que entramos en modo UEFI
ls /sys/firmware/efi/efivars

# -- scripts a ejecutar desde el archiso ---------------------------------------
export HOSTNAME=ghost && \
pacman -Syy && \
pacman -S --noconfirm --needed git && \
git clone https://github.com/1noro/arch-installs.git && \
cd "arch-installs/computers/${HOSTNAME}" && \
bash 1-archiso-steps.sh

# reboot

# -- scripts a ejecutra en el primer inicio del sistema ------------------------
# iniciamos sesión como "cosmo"
export HOSTNAME=ghost && \
git clone https://github.com/1noro/arch-installs.git && \
cd "arch-installs/computers/${HOSTNAME}" && \
bash 2-first-boot-steps.sh && \
cd && \
rm -rf arch-installs

# reboot
