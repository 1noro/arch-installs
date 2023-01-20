#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

source /opt/.env


# -- PACMAN --------------------------------------------------------------------
# el mirrorlis ya está optimizado en el script anterior

# -- editamos la configuración
# nvim /etc/pacman.conf
# descomentar las siguientes lineas:
# - en Misc options:
#Color
#VerbosePkgLists
#ParallelDownloads = 3
# - en los repositorios:
#[multilib]
#Include = /etc/pacman.d/mirrorlist

sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/VerbosePkgLists/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads = 5/s/^#//g' /etc/pacman.conf

# sed -i '/\[multilib\]/s/^#//g' /etc/pacman.conf
# Include = /etc/pacman.d/mirrorlist
# sed -i '/^#\[multilib]/{N;s/\n#/\n/}' /etc/pacman.conf
# !!!!esto no está funcionando

echo "# aggregated during installation
[multilib]
Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

pacman -Syyu --noconfirm # actualizamos el sistema

# -- agregamos el hook (trigger) para limpiar la cache de pacman
# https://wiki.archlinux.org/index.php/Pacman_(Espa%C3%B1ol)#Limpiar_la_memoria_cach%C3%A9_de_los_paquetes
pacman -S --noconfirm --needed pacman-contrib
mkdir -p /etc/pacman.d/hooks/
echo "[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning pacman cache...
When = PostTransaction
Exec = /usr/bin/paccache -r" >> /etc/pacman.d/hooks/remove_old_cache.hook


# -- USUARIOS ------------------------------------------------------------------
# asignamos una contrseña a root
echo -e "## Contraseña para \e[36mroot\e[m"
passwd

# creamos y configuramos un nuevo usuario para podrer instalar paquetes desde AUR
# (considerar quitar la opción -m "create home")
useradd -s /bin/bash -m "${USER}"
echo -e "## Contraseña para \e[36m${USER}\e[m"
passwd "${USER}"
# usermod -a -G sudo "${USER}"
# --- inicio sudo manual ---
# env EDITOR=nvim visudo
# agregar la siguiente linea:
# cosmo ALL=(ALL) ALL
# --- fin sudo manual ---
echo "${USER}	ALL=(ALL) ALL" >> /etc/sudoers


# -- HORA ----------------------------------------------------------------------
# configuramos la hora (no se porqué esto no funcinó bien la primera vez y
# luego tuve que volver a configurarlo desde gnome)
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc


# -- IDIOMA --------------------------------------------------------------------
# configuramos el idioma por defecto del equipo
# nvim /etc/locale.gen
# descomentamos:
# en_US.UTF-8 UTF-8
# es_ES.UTF-8 UTF-8
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i '/es_ES.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf


# -- HOSTNAME ------------------------------------------------------------------
# ponemos nombre al equipo
echo "$HOSTNAME" > /etc/hostname
# nvim /etc/hosts
# - agregar las siguientes lineas
{
    echo "127.0.0.1	localhost"
    echo "::1		localhost"
    echo "127.0.1.1	$HOSTNAME.$LAN_DOMAIN	$HOSTNAME"
} >> /etc/hosts


# --- MÓDULOS DEL KERNEL -------------------------------------------------------
# agregamos el módulo i915 al kernel de Linux y lo volvemos a configurar
# esto es para cargar KMS lo antes posible al inicio del boot
# https://wiki.archlinux.org/index.php/Kernel_mode_setting_(Espa%C3%B1ol)
#
# *Corrección: esto es para que el módulo de los gráficos de intel (i915) se 
# incorpore al initramfs para que se cargue con el primer arranque del kernel.
# Y se compile automáticamente al actualizar el kernel con pacaman.
# nvim /etc/mkinitcpio.conf
# modificar la linea MODULES=() --> MODULES=(i915)
sed -i 's/MODULES=()/MODULES=(i915)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
# comprobar aquí si falta algún módulo por cargar para este hardware específico


# -- GESTOR DE ARRANQUE DEL SISTEMA --------------------------------------------
# TODO: esto es específico del hardware, hay que moverlo a un script específico
# instalamos y habilitamos las actualizacionse tempranas de microcodigo
# para procesadores intel
# pacman -S --noconfirm --needed intel-ucode

# -- instalación y configuración inicial de GRUB
pacman -S --noconfirm --needed grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
# https://wiki.archlinux.org/index.php/Kernel_parameters_(Espa%C3%B1ol)
# https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
# https://wiki.archlinux.org/index.php/Improving_performance#Watchdogs
# https://wiki.archlinux.org/index.php/Intel_graphics#Enable_early_KMS
# nvim /etc/default/grub
# editando la linea GRUB_CMDLINE_LINUX_DEFAULT para dejarla así:
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 nowatchdog i915.enable_guc=2"
sed -i 's/loglevel=3 quiet/loglevel=4 nowatchdog i915.enable_guc=2 snd_hda_codec_hdmi.enable_silent_stream=0/g' /etc/default/grub
# de paso, también reducimos el tiempo de espera en la pantalla de grub
# GRUB_TIMEOUT=2
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


# -- SSH -----------------------------------------------------------------------
# instalamos, habilitamos y ejecutamos ssh para poder continuar con la
# instalación desde otro pc de forma remota
pacman -S --noconfirm --needed openssh
# !!!!esto esta fallando:
# (2/4) Creating temporary files...
# Failed to open file "/sys/devices/system/cpu/microcode/reload": Read-only file system
# error: command failed to execute correctly
systemctl enable sshd


# -- SSD (optimizar y aumentar su vida) ----------------------------------------
# TODO: refactorizar esto para que la comprobación de TRIM sea automática
# To verify TRIM support, run:
lsblk --discard
# And check the values of DISC-GRAN (discard granularity) and DISC-MAX (discard
# max bytes) columns. Non-zero values indicate TRIM support.
systemctl enable fstrim.timer


# -- FIRST BOOT NETWORK SERVICE ------------------------------------------------
# instalamos y habilitamos el demonio más básico de dhcp para que al reiniciar
# no nos quedemos sin internet
pacman -S --noconfirm --needed dhcpcd
# !!!!esto esta fallando:
# (2/4) Creating temporary files...
# Failed to open file "/sys/devices/system/cpu/microcode/reload": Read-only file system
# error: command failed to execute correctly
systemctl enable dhcpcd


echo "## FIN ##"
