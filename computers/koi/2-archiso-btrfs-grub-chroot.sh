#!/bin/bash
# koi btrfs (GRUB) ARCHISO
# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

set -e

if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# asignamos una contrseña a root
passwd

# creamos y configuramos un nuevo usuario para podrer instalar paquetes desde AUR
useradd -s /bin/fish -m cosmo # considerar quitar la opción -m (create_home)
passwd cosmo
# usermod -a -G sudo cosmo
# --- inicio sudo manual ---
env EDITOR=nvim visudo
# agregar la siguiente linea:
# cosmo ALL=(ALL) ALL
# --- fin sudo manual ---

# Si recreamos /home/cosmo manualmente hay que ejecutar:
# chown cosmo:cosmo /home/cosmo # considerar poner -R
# si no creamos /home/cosmo manualmente es recomendable ajustar los permisos:
# chmod 755 /home/cosmo
# (AHORA USA DOCKER PUTO)

# instalamos, habilitamos y ejecutamos ssh para poder continuar con la
# instalación desde otro pc de forma remota
pacman -S --noconfirm --needed openssh
systemctl enable sshd

# configuramos la hora (no se porqué esto no funcinó bien la primera vez y
# luego tuve que volver a configurarlo desde gnome)
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# configuramos el idioma por defecto del equipo
# nano /etc/locale.gen
# descomentamos:
# en_US.UTF-8 UTF-8
# es_ES.UTF-8 UTF-8
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i '/es_ES.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo 'LANG=es_ES.UTF-8' > /etc/locale.conf

# ponemos nombre al equipo
echo 'punk' > /etc/hostname
# nano /etc/hosts
# - agregar las siguientes lineas
{
    echo '127.0.0.1	localhost'
    echo '::1		localhost'
    echo '127.0.1.1	punk.jamaica.h.a3do.net	punk'
} >> /etc/hosts

# instalamos y habilitamos el demonio más básico de dhcp para que al reiniciar
# no nos quedemos sin internet
pacman -S --noconfirm --needed dhcpcd
systemctl enable dhcpcd

# --- módulos de kernel necesarios
# agregamos el módulo i915 al kernel de Linux y lo volvemos a configurar
# esto es para cargar KMS lo antes posible al inicio del boot
# https://wiki.archlinux.org/index.php/Kernel_mode_setting_(Espa%C3%B1ol)
#
# *Corrección: esto es para que el módulo de los gráficos de intel (i915) se 
# incorpore al initramfs para que se cargue con el primer arranque del kernel.
# Y se compile automáticamente al actualizar el kernel con pacaman.
# nano /etc/mkinitcpio.conf
# modificar la linea MODULES=() --> MODULES=(i915)
sed -i 's/MODULES=()/MODULES=(i915)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
# comprobar aquí si falta algún módulo por cargar para este hardware específico

# --- INICIO DE COMANDOS EXCLUSIVOS PARA KOI -----------------------------------
# (https://gist.github.com/imrvelj/c65cd5ca7f5505a65e59204f5a3f7a6d)
# solución para los warnings:
# ==> WARNING: Possibly missing firmware for module: aic94xx
# ==> WARNING: Possibly missing firmware for module: wd719x
su cosmo -c 'mkdir -p ~/Work/aur'

su cosmo -c 'cd ~/Work/aur && \
    git clone https://aur.archlinux.org/aic94xx-firmware.git && \
    cd aic94xx-firmware && \
    makepkg -sri'

su cosmo -c 'cd ~/Work/aur && \
    git clone https://aur.archlinux.org/wd719x-firmware.git && \
    cd wd719x-firmware && \
    makepkg -sri'

# según los foros esto no es necesario, pero a mi me funciona para quitar el 
# WARNING al recompilar los módulos dinámicos del nucleo.
# ==> WARNING: Possibly missing firmware for module: xhci_pci
su cosmo -c 'cd ~/Work/aur && \
    git clone https://aur.archlinux.org/upd72020x-fw.git && \
    cd upd72020x-fw && \
    makepkg -sri'

mkinitcpio -p linux # volvemos a generar el initramfs en /boot

# --- FINAL DE COMANDOS EXCLUSIVOS PARA KOI ------------------------------------

# --- GESTOR DE ARRANQUE DEL SISTEMA -------------------------------------------

# instalamos y habilitamos las actualizacionse tempranas de microcodigo
# para procesadores intel
pacman -S --noconfirm --needed intel-ucode

# -- instalación y configuración inicial de GRUB
pacman -S --noconfirm --needed grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# https://wiki.archlinux.org/index.php/Kernel_parameters_(Espa%C3%B1ol)
# https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
# https://wiki.archlinux.org/index.php/Improving_performance#Watchdogs
# https://wiki.archlinux.org/index.php/Intel_graphics#Enable_early_KMS
# nano /etc/default/grub
# editando la linea GRUB_CMDLINE_LINUX_DEFAULT para dejarla así:
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 nowatchdog i915.enable_guc=2"
sed -i 's/loglevel=3 quiet/loglevel=4 nowatchdog i915.enable_guc=2/g' /etc/default/grub
# de paso, también reducimos el tiempo de espera en la pantalla de grub
# GRUB_TIMEOUT=2
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# --- FIN GESTOR DE ARRANQUE DEL SISTEMA ---------------------------------------
