#!/bin/bash

set -e

if [[ $(id -u) -eq 0 ]]; then
    echo "This script must be run as a non-root user"
    exit 1
fi

USER="cosmo"

# -- DOTFILES ------------------------------------------------------------------
# (EL SCRIPT DEPLOY AÚN NO ESTÁ FUNCIONANDO, es mas, nada funciona)
# mkdir -p ~/Work/github
# cd ~/Work/github
# git clone https://github.com/1noro/dotfiles.git; \
# cd dotfiles; \
# bash deploy.sh; \
# cd; \
# source ~/.zshrc # para recargar el .zshrc sin reiniciar la shell


# -- PILA GRÁFICA Y ESCRITORIO -------------------------------------------------
# comprobación de la tarjeta gráfica
# lspci | grep VGA

# > FOR VIRTUALBOX GUESTS READ:
# https://wiki.archlinux.org/index.php/VirtualBox/Install_Arch_Linux_as_a_guest
# https://wiki.archlinux.org/index.php/VirtualBox#Set_guest_starting_resolution
# esencaialmente solo hay que substitur la instalacíon de xf86-video-intel por estos dos comandos
# sudo pacman -S --noconfirm --needed virtualbox-guest-utils
# sudo systemctl enable vboxservice.service

# driver de la tarjeta grafica
sudo pacman -S --noconfirm --needed xf86-video-intel
# instalar OpenGl y OpenGl 32 (para Steam, por ejemplo) los paquetes -utils 
# pueden no ser necesarios, pero ofrecen algunas utilidades para verificar el 
# correcto funcionamiento de la pila gráfica
sudo pacman -S --noconfirm --needed mesa lib32-mesa mesa-utils lib32-mesa-utils
# instalamos los paquietes de Vulkan para poder ejecutar Proton con Steam
sudo pacman -S --noconfirm --needed vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    vulkan-tools
# Instalamos el driver específico de Intel para Vulkan
sudo pacman -S --noconfirm --needed vulkan-intel lib32-vulkan-intel

# -- inicio pipewire --
# instalamos pipewire y sus dependencias
sudo pacman -S --noconfirm --needed pipewire \
    lib32-pipewire \
    pipewire-docs \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    lib32-pipewire-jack \
    gst-plugin-pipewire \
    pavucontrol
# PARECE QUE ESTE PAQUERTE NO HACE FALTA:
# cd ~/Work/aur; \
# git clone https://aur.archlinux.org/pipewire-dropin.git; \
# cd pipewire-dropin; \
# makepkg -sri; \
# cd ~
# comprobaciones para realizar después: https://wiki.archlinux.org/title/PipeWire
# comando util por si trajeta USB no funciona:
# systemctl --user restart pipewire.service
# info sobre jack: https://github.com/jackaudio/jackaudio.github.com/wiki/Q_difference_jack1_jack2
# -- final pipewire --

# instalamos gnome y sus extras
sudo pacman -S --noconfirm --needed gdm \
    gnome \
    gnome-extra \
    gnome-themes-extra \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    gnu-free-fonts \
    noto-fonts-emoji \
    firefox
# gdm ya está en el grupo gnome, pero lo escribo para que quede patente
# especifico xdg-desktop-portal-gtk para no tener que leer la wiki siempre
# TODO: revisar las diferencias entre xdg-desktop-portal-gtk y 
# xdg-desktop-portal-kde

# habilitamos gdm para que se inicie solo
sudo systemctl enable gdm


# -- default MIME types --------------------------------------------------------
# para que funcione la opción ver en carpeta de los programas como firefox, etc
# (resumiendo: permitir a firefox que pueda abrir nautilus cuando quieres ver tus descargas en su carpeta)
# xdg-mime default org.gnome.Nautilus.desktop inode/directory
# (parece que ya no hace falta)


# -- NetworkManager ------------------------------------------------------------
# instalamos NetworkManager para poder gestionar la red desde gnome
sudo pacman -S --noconfirm --needed wpa_supplicant \
    wireless_tools \
    networkmanager \
    network-manager-applet \
    openvpn \
    networkmanager-openvpn \
    gnome-keyring

# systemctl --type=service # (comprobación)
sudo systemctl stop dhcpcd
sudo systemctl disable dhcpcd
sudo pacman -Rns --noconfirm dhcpcd

sudo systemctl enable wpa_supplicant
sudo systemctl enable NetworkManager

# add user to network group
sudo gpasswd -a "$USER" network


# -- Bluetooth -----------------------------------------------------------------
sudo pacman -S --noconfirm --needed bluez bluez-utils bluez-tools --needed
# verificamos que el modulo btusb está cargado en el kernel
lsmod | grep btusb
sudo systemctl enable bluetooth


# --- INICIO DE COMANDOS EXCLUSIVOS PARA MPU -----------------------------------
sudo mkdir -p /opt/aur
sudo chown cosmo:cosmo /opt/aur
cd /opt/aur

# (https://gist.github.com/imrvelj/c65cd5ca7f5505a65e59204f5a3f7a6d)
# solución para los warnings:
# ==> WARNING: Possibly missing firmware for module: aic94xx
# ==> WARNING: Possibly missing firmware for module: wd719x
git clone https://aur.archlinux.org/aic94xx-firmware.git && \
cd aic94xx-firmware && \
makepkg -sri --noconfirm

git clone https://aur.archlinux.org/wd719x-firmware.git && \
cd wd719x-firmware && \
makepkg -sri --noconfirm

# según los foros esto no es necesario, pero a mi me funciona para quitar el 
# WARNING al recompilar los módulos dinámicos del nucleo.
# ==> WARNING: Possibly missing firmware for module: xhci_pci
git clone https://aur.archlinux.org/upd72020x-fw.git && \
cd upd72020x-fw && \
makepkg -sri --noconfirm

cd "$HOME"

sudo mkinitcpio -p linux # volvemos a generar el initramfs en /boot
# --- FINAL DE COMANDOS EXCLUSIVOS PARA MPU ------------------------------------


# -- primera snapshot en btrfs -------------------------------------------------
sudo pacman -S --noconfirm --needed snapper

sudo snapper -c root create-config / && \
sudo snapper -c root create -d "primera" && \
sudo snapper -c home create-config /home && \
sudo snapper -c home create -d "primera"


## -- FINALIZACIÓN -------------------------------------------------------------
echo "## FIN ##"
