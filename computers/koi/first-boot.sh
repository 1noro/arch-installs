#!/bin/bash
# Arch Linux custom build
# (btrfs snapper gnome wayland pipewire)
# Maintainer 1noro <https://github.com/1noro>

set -e

if [[ $(id -u) -eq 0 ]]; then
    echo "This script must be run as a non-root user"
    exit 1
fi

source .env


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
sudo pacman -S --noconfirm --needed \
     mesa \
     lib32-mesa \
     mesa-utils \
     lib32-mesa-utils
# instalamos los paquietes de Vulkan para poder ejecutar Proton con Steam
sudo pacman -S --noconfirm --needed \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    vulkan-tools
# Instalamos el driver específico de Intel para Vulkan
sudo pacman -S --noconfirm --needed \
    vulkan-intel \
    lib32-vulkan-intel

# -- inicio pipewire --
# instalamos pipewire y sus dependencias
sudo pacman -S --noconfirm --needed 
    pipewire \
    lib32-pipewire \
    pipewire-docs \
    wireplumber \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    lib32-pipewire-jack \
    gst-plugin-pipewire \
    qpwgraph \
    helvum
# (no me decido entre qpwgraph y helvum)
# comprobaciones para realizar después: https://wiki.archlinux.org/title/PipeWire
# comando util por si trajeta USB no funciona:
# systemctl --user restart pipewire.service
# info sobre jack: https://github.com/jackaudio/jackaudio.github.com/wiki/Q_difference_jack1_jack2
# -- final pipewire --

# instalamos gnome y sus extras
sudo pacman -S --noconfirm --needed 
    gdm \
    gnome \
    gnome-extra \
    gnome-themes-extra \
    gnome-keyring \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    gnu-free-fonts \
    noto-fonts-emoji \
    firefox
# gdm ya está en el grupo gnome, pero lo escribo para que quede patente
# especifico xdg-desktop-portal-gtk para no tener que leer la wiki siempre

# habilitamos gdm para que se inicie solo
sudo systemctl enable gdm

# set night-light-enabled in GDM
sudo -u gdm dbus-launch gsettings \
    set org.gnome.settings-daemon.plugins.color night-light-enabled true


# -- default MIME types --------------------------------------------------------
# para que funcione la opción ver en carpeta de los programas como firefox, etc
# (resumiendo: permitir a firefox que pueda abrir nautilus cuando quieres ver
# tus descargas en su carpeta)
# xdg-mime default org.gnome.Nautilus.desktop inode/directory
# (parece que ya no hace falta)


# -- NetworkManager ------------------------------------------------------------
# instalamos NetworkManager para poder gestionar la red desde gnome
sudo pacman -S --noconfirm --needed \
    wpa_supplicant \
    wireless_tools \
    networkmanager \
    network-manager-applet \
    openvpn \
    networkmanager-openvpn

# systemctl --type=service # (comprobación)
sudo systemctl stop dhcpcd
sudo systemctl disable dhcpcd
sudo pacman -Rcns --noconfirm dhcpcd

sudo systemctl enable wpa_supplicant
sudo systemctl enable NetworkManager

# add ${USER} to network group
sudo gpasswd -a "${USER}" network


# -- Bluetooth -----------------------------------------------------------------
# borramos el paquete "gnome-bluetooth" ya que se instala con los extras de
# gnome y está marcado como legacy. El paquete bueno es "gnome-bluetooth-3.0"
# mas info: https://wiki.archlinux.org/title/Bluetooth#Graphical
# pongo el "|| true" por si en un futuro ya no se instala por defecto
sudo pacman -Rcns gnome-bluetooth || true

sudo pacman -S --noconfirm --needed \
    bluez \
    bluez-utils \
    bluez-tools
# verificamos que el modulo btusb está cargado en el kernel
lsmod | grep btusb
# habilitamos el servicio bluetooth
sudo systemctl enable bluetooth
# agregamos ${USER} a la grupo bluetooth (llamado "lp")
usermod -a -G lp "${USER}"


# -- AUR -----------------------------------------------------------------------
# creamos la carpeta donde gaurdaremos los repos de AUR
sudo mkdir -p /opt/aur
sudo chown "${USER}":"${USER}" /opt/aur


# -- INICIO DE COMANDOS EXCLUSIVOS PARA ${HOSTNAME} ----------------------------
bash "${HOSTNAME}-specific.sh"
# -- FINAL DE COMANDOS EXCLUSIVOS PARA ${HOSTNAME} -----------------------------


# -- PACMAN: snap-pac ----------------------------------------------------------
# agregamos el hook (trigger) para crear una snapshot antes y 
# despues de la instalación de paquetes
# (primero creamos una config de snapper para ${ROOT_SUBVOL})
snapper -c "${ROOT_SUBVOL}" create-config /
# instalamos snap-pac
pacman -S --noconfirm --needed snap-pac
# configuramos snap-pac
echo "[${ROOT_SUBVOL}]
snapshot = True
important_packages = [\"linux\"]
important_commands = [\"pacman -Syu\", \"pacman -Syyu\"]
desc_limit = 72
" >> /etc/snap-pac.ini

# -- creamos la snapshot inicial con el sistema recien instalado ---------------
sudo snapper -c "${ROOT_SUBVOL}" \
    create -d "primera snapshot de ${ROOT_SUBVOL} (recien instalado)"

# comprobación
# sudo snapper -c "${ROOT_SUBVOL}" list


## -- FINALIZACIÓN -------------------------------------------------------------
echo "## FIN ##"
