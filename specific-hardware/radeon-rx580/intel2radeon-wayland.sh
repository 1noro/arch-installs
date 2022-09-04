#!/bin/bash
# RUN AS ROOT
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

### BORRAR CONFIGURACIÓN INTEL GRAPHICS ########################################
## Quitamos los módulos de kernel de intel del mkinitcpio.conf
# agregamos el módulo i915 al kernel de Linux y lo volvemos a configura
# esto es para cargar KMS lo antes posible al inicio del boot
# https://wiki.archlinux.org/index.php/Kernel_mode_setting_(Espa%C3%B1ol)
# - Módulos del kernel
nano /etc/mkinitcpio.conf
# modificar la linea MODULES=(i915) --> MODULES=()
mkinitcpio -p linux

# comprobar aquí si falta algún módulo por cargar para este hardware específico

# - Configuración del grub
nano /etc/default/grub
# modificar la siguiente línea
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 nowatchdog i915.enable_guc=2 snd_hda_codec_hdmi.enable_silent_stream=0 irqpoll"
# para que quede así
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 nowatchdog snd_hda_codec_hdmi.enable_silent_stream=0 irqpoll"
grub-mkconfig -o /boot/grub/grub.cfg

## Ponemos en la lista negra los módulos de Intel
echo 'install i915 /bin/false' >> /etc/modprobe.d/blacklist.conf
echo 'install intel_agp /bin/false' >> /etc/modprobe.d/blacklist.conf

## Borramos los drivers de la tarjeta de intel
pacman -Rns xf86-video-intel

## Borramos los drivers de Vulkan Intel
pacman -Rns vulkan-intel lib32-vulkan-intel

### INSTALAMOS LOS PAQUETES DE AMDGPU ##########################################
## Instalamos el DDX driver
pacman -S --noconfirm --needed xf86-video-amdgpu

## Instalamos los drivers Vulkan Radeon
pacman -S --noconfirm --needed vulkan-radeon

## Instalamos el soporte para accelerated video decoding
pacman -S --noconfirm --needed \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    mesa-vdpau \
    lib32-mesa-vdpau
