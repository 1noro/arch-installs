#!/bin/bash
# koi btrfs (GRUB) ARCHISO manual steps
# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

# -- comprobaciones iniciales --------------------------------------------------
# comprobación de red DHCP (por cable)
ping archlinux.org

# activamos el servidor SSH y configuramos una contraseña para root
# por si queremos realizar la instalación de forma remota
systemctl start sshd
passwd
ip addr

# verificamos que entramos en modo UEFI
ls /sys/firmware/efi/efivars

# -- particionado del disco ----------------------------------------------------
# comprobación de discos
lsblk

# - tabla de particiones GPT (GRUB)
# https://wiki.archlinux.org/index.php/EFI_system_partition#GPT_partitioned_disks
# https://gtronick.github.io/ALIG/
# NAME            SIZE  TYPE                    MOUNTPOINT
# sda           223,6G  disk
#   sda1        512,0M  part EFI System (ESP)   /boot
#   sda2         16,0G  part                    [SWAP]
#   sda3        207,1G  part                    [BTRFS VOLUMES]

fdisk /dev/sda
# comandos de fdisk:
# m (listamos la ayuda)
# g (generamos una tabla GPT)
# n (creamos sda1)
# t (se selecciona automaticamente la única particion creada)
# 1 (cambiamos el tipo a EFI System)
# n (creamos sda2)
# n (creamos sda3)
# p (mostramos cómo va a quedar el resultado)
# w (escribimos los cambios y salimos)

# comprobación de particiones
lsblk

# -- ejecución de scripts ------------------------------------------------------
pacamn -Syy && pacman -S --noconfirm --needed git
git clone https://github.com/1noro/arch-installs.git

# script base
bash arch-installs/computers/koi/1-archiso-base.sh /dev/sda

# script chroot
cp arch-installs/computers/koi/2-archiso-chroot.sh /mnt/tmp/
arch-chroot /mnt bash /tmp/2-archiso-chroot.sh

# -- pasos finales -------------------------------------------------------------
# desmontamos con seguridad el entorno de instalación
sync && umount -R /mnt

# reiniciamos
reboot
