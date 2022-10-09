#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

source .env


# -- verificamos que entramos en modo UEFI
ls -A /sys/firmware/efi/efivars

# -- activamos el servidor ntp para la hora
timedatectl set-ntp true
echo "## comprobamos la hora NTP"
timedatectl status # (verificación)

# -- formateo del disco --------------------------------------------------------
# lsblk -fm
mkfs.fat -F32 -n EFI "${HDD}${PART_PREFIX}1"
mkswap -L swap "${HDD}${PART_PREFIX}2"
swapon -L swap
# (nótese que aquí asignamos el nombre "${MAIN_PARTITION}" a nuestra partición)
mkfs.btrfs --force --label "${MAIN_PARTITION}" "${HDD}${PART_PREFIX}3"

# definimos las variables "o" y "o_btrfs" para las opciones de montaje
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime

# montamos nuestra partición "${MAIN_PARTITION}" en /mnt
mount -t btrfs LABEL="${MAIN_PARTITION}" /mnt

# creamos los subvolumes btrfs
btrfs subvolume create "/mnt/${ROOT_SUBVOL}"
btrfs subvolume create "/mnt/${SRV_SUBVOL}"
btrfs subvolume create "/mnt/${VAR_SUBVOL}"
btrfs subvolume create "/mnt/${HOME_ROOT_SUBVOL}"
btrfs subvolume create "/mnt/${HOME_SUBVOL}"

# desmontamos todo
umount -R /mnt

# y ahora montamos los sobvolumenes en su orden correspondiente
mount -t btrfs -o subvol="${ROOT_SUBVOL}",$o_btrfs LABEL="${MAIN_PARTITION}" /mnt
mount -t btrfs -o subvol="${SRV_SUBVOL}",$o_btrfs LABEL="${MAIN_PARTITION}" /mnt/srv
mount -t btrfs -o subvol="${VAR_SUBVOL}",$o_btrfs LABEL="${MAIN_PARTITION}" /mnt/var
mount -t btrfs -o subvol="${HOME_ROOT_SUBVOL}",$o_btrfs LABEL="${MAIN_PARTITION}" /mnt/root
mount -t btrfs -o subvol="${HOME_SUBVOL}",$o_btrfs LABEL="${MAIN_PARTITION}" /mnt/home

# montamos la partición EFI
mount LABEL=EFI -o $o /mnt/boot
lsblk

# -- instalacion del sistema base ----------------------------------------------
# instalamos el sistema base en el disco particionado
# https://wiki.archlinux.org/index.php/Mirrors_(Espa%C3%B1ol)#Lista_por_velocidad
# nvim /etc/pacman.d/mirrorlist
# agregar al principio de todo las lineas:
# Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch
# Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch
sed -i '1 i\Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
sed -i '1 i\Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
sed -i '/ParallelDownloads = 5/s/^#//g' /etc/pacman.conf
pacman -Syy # refrescamos los repositorios al cambiar el mirrorlist
pacstrap /mnt base \
    base-devel \
    linux \
    linux-firmware \
    dosfstools \
    exfat-utils \
    btrfs-progs \
    e2fsprogs \
    ntfs-3g \
    nfs-utils \
    man-db \
    man-pages \
    texinfo \
    sudo \
    git \
    neovim \
    snapper
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# - este mensaje es completamente normal mientras no generemos los locales
# perl: warning: Setting locale failed.
# perl: warning: Please check that your locale settings:
# 	LANGUAGE = (unset),
# 	LC_ALL = (unset),
# 	LC_MESSAGES = "",
# 	LANG = "en_US.UTF-8"
#     are supported and installed on your system.
# perl: warning: Falling back to the standard locale ("C").

# -- generamos el fstab tal cual como lo tenemos montado en la instalación
# genfstab -U /mnt > /mnt/etc/fstab # Use UUIDs for source identifiers
genfstab -L /mnt > /mnt/etc/fstab # Use labels for source identifiers

# -- fin de la instalación base ------------------------------------------------

echo "## FIN ##"
