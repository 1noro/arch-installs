#!/bin/bash
# koi btrfs (GRUB) ARCHISO BASE

set -e

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <HDD_DEVICE>"
    echo "Example: $0 /dev/sda"
    exit 1
fi

HDD=$1

# -- verificamos que entramos en modo UEFI
ls -A /sys/firmware/efi/efivars

# -- activamos el servidor ntp para la hora
timedatectl set-ntp true
echo "## comprobamos la hora NTP"
timedatectl status # (verificación)

# -- formateo del disco --------------------------------------------------------
# lsblk -fm
mkfs.fat -F32 -n EFI "${HDD}1"
mkswap -L swap "${HDD}2"
swapon -L swap
mkfs.btrfs --force --label system "${HDD}3" # nótese que aquí asignamos el nombre "system" a nuestra partición

# definimos las variables "o" y "o_btrfs" para las opciones de montaje
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime

# montamos nuestra partición "system" en /mnt
mount -t btrfs LABEL=system /mnt

# creamos los subvolumes btrfs
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
#btrfs subvolume create /mnt/snapshots # puede que en el futuro si uso snapper esto no haga falta

# desmontamos todo
umount -R /mnt

# y ahora montamos los sobvolumenes en su orden correspondiente
mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
#mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/.snapshots # puede que en el futuro si uso snapper esto no haga falta

# montamos la partición EFI
mkdir /mnt/boot
mount LABEL=EFI /mnt/boot
lsblk

# -- instalacion del sistema base ----------------------------------------------
# instalamos el sistema base en el disco particionado (pensar en que paquetes 
# son necesarios aquí desde el principio)
# nvim /etc/pacman.d/mirrorlist
# agregar al principio de todo las lineas:
# Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch
# Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch
sed -i '1 i\Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
sed -i '1 i\Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
pacman -Syy # refrescamos los repositorios al cambiar el mirrorlist
pacstrap /mnt base base-devel linux linux-firmware dosfstools exfat-utils btrfs-progs e2fsprogs ntfs-3g nfs-utils man-db man-pages texinfo sudo git neovim fish
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
# -- copiamos el siguiente script a la carpeta correspondiente
cp arch-installs/computers/koi/archiso-chroot.sh /mnt/opt/

echo "## FIN ##"
