#!/bin/bash
# koi btrfs (GRUB) ARCHISO manual steps
# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

# -- comprobación de red DHCP (por cable)
ping archlinux.org

# -- activamos el servidor SSH y configuramos una contraseña para root
# por si queremos realizar la instalación de forma remota
systemctl start sshd
passwd
ip addr

# -- verificamos que entramos en modo UEFI
ls /sys/firmware/efi/efivars
