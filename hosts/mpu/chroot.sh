# hosts/mpu/chroot.sh — se carga (source) al final de lib/chroot-setup.sh.
# shellcheck shell=bash

# puntos de montaje del NAS (ver fstab.extra)
mkdir -p /nfs/{Backups,Downloads,Homedir,Videos,Music,MusicRO}

# Pendiente (config con credenciales, no se guarda en el repo): /etc/nut/* para
# nut-server / nut-monitor. Cuando esté, activar con: systemctl enable --now nut-server nut-monitor
