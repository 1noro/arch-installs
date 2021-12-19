#!/bin/bash
# koi FIRSTBOOT

# iniciamos sesión como "cosmo"
# su cosmo
# (EL SCRIPT DEPLOY AÚN NO ESTÁ FUNCIONANDO)
mkdir -p ~/Work/github
cd ~/Work/github
git clone https://github.com/1noro/dotfiles.git; \
cd dotfiles; \
bash deploy.sh; \
cd; \
source ~/.zshrc # para recargar el .zshrc sin reiniciar la shell

# --- configuración de pacman
# copiar el archivo mirrorlist de esta configuración en /etc/pacman.d/mirrorlist
# o generar uno por velocidad como se describe en la wiki:
# https://wiki.archlinux.org/index.php/Mirrors_(Espa%C3%B1ol)#Lista_por_velocidad
sudo nano /etc/pacman.conf
# descomentar las siguientes lineas:
# - en Misc options:
#Color
#VerbosePkgLists
#ParallelDownloads = 3
# - en los repositorios:
#[multilib]
#Include = /etc/pacman.d/mirrorlist
sudo pacman -Syyu # actualizamos el sistema
sudo pacman -S pacman-contrib

# agregamos el hook (trigger) para limpiar la cache de pacman
# https://wiki.archlinux.org/index.php/Pacman_(Espa%C3%B1ol)#Limpiar_la_memoria_cach%C3%A9_de_los_paquetes
sudo mkdir -p /etc/pacman.d/hooks/
sudo nano /etc/pacman.d/hooks/remove_old_cache.hook
# - Escribe lo siguiente:
# [Trigger]
# Operation = Upgrade
# Operation = Install
# Operation = Remove
# Type = Package
# Target = *

# [Action]
# Description = Cleaning pacman cache...
# When = PostTransaction
# Exec = /usr/bin/paccache -r

# --- instalando los gráficos
# > FOR VIRTUALBOX GUESTS READ: 
# https://wiki.archlinux.org/index.php/VirtualBox/Install_Arch_Linux_as_a_guest
# https://wiki.archlinux.org/index.php/VirtualBox#Set_guest_starting_resolution
# esencaialmente solo hay que substitur la instalacíon de xf86-video-intel por estos dos comandos
# sudo pacman -S virtualbox-guest-utils
# sudo systemctl enable vboxservice.service

lspci | grep VGA
sudo pacman -S xf86-video-intel # driver de la tarjeta grafica
sudo pacman -S mesa lib32-mesa --needed # instalar OpenGl y OpenGl 32 (para Steam, por ejemplo)
# --- inicio pipewire ---
sudo pacman -S pipewire lib32-pipewire pipewire-docs pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack gst-plugin-pipewire pavucontrol # instalamos pipewire
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
# --- final pipewire ---
sudo pacman -S gdm gnome gnome-extra xdg-desktop-portal xdg-desktop-portal-gtk gnu-free-fonts noto-fonts-emoji
# gdm ya está en el grupo gnome, pero lo escribo para que quede patente
# especifico xdg-desktop-portal-gtk para no tener que leer la wiki siempre
# revisar las diferencias entre xdg-desktop-portal-gtk y xdg-desktop-portal-kde
sudo systemctl enable gdm


# --- instalando y configurando NetworkManager
# instalamos NetworkManager para poder gestionar la red desde gnome
sudo pacman -S wpa_supplicant wireless_tools networkmanager network-manager-applet gnome-keyring --needed

# systemctl --type=service
sudo systemctl stop dhcpcd; \
sudo systemctl disable dhcpcd; \
sudo pacman -Rns dhcpcd

sudo systemctl enable wpa_supplicant; \
sudo systemctl enable NetworkManager

# add cosmo to network group
sudo gpasswd -a cosmo network # agregar tambien a c


# --- instalando y configurando el Bluetooth (en caso de estar presente en el equipo)
sudo pacman -S bluez bluez-utils bluez-tools --needed
# verificamos que el modulo btusb está cargado en el kernel
lsmod | grep btusb
sudo systemctl enable bluetooth

# reiniciamos para que se apliquen todos estos cambios importantes
sudo reboot


# instalamos un navegador de internet decente
sudo pacman -S firefox
# - configuramos firefox para evitar el tearing forzando la aceleración por hardware
# en los ajustes de fírefox ir a General > Rendimiento
# desmarcamos Usar configuración de rendimiento recomendada
# y verificamos que quede marcado Usar aceleración de hardware cuando esté disponible
# y el ímite de procesadores el recomendado (8, por ejemplo)


# -- SSD (optimizar y aumentar su vida)
# To verify TRIM support, run:
lsblk --discard
# And check the values of DISC-GRAN (discard granularity) and DISC-MAX (discard
# max bytes) columns. Non-zero values indicate TRIM support.
sudo systemctl enable fstrim.timer


# -- default MIME types
# para que funcione la opción ver en carpeta de los programas como firefox, etc
# (resumiendo: permitir a firefox que pueda abrir nautilus cuando quieres ver tus descargas en su carpeta)
# xdg-mime default org.gnome.Nautilus.desktop inode/directory
# (parece que ya no hace falta)


# -- agregamos un fondo para que el GRUB quede to chulo:
# (si se usa systemd-boot no hace falta)
cd ~/Work/github
git clone https://github.com/1noro/gnu-linux-configs.git
sudo cp ~/Work/github/gnu-linux-configs/archlinux/grub-bg.png /boot/grub/grub-bg.png
sudo nano /etc/default/grub
# descomentamos y editamos las lineas:
# GRUB_BACKGROUND="/boot/grub/grub-bg.png"
# #GRUB_GFXMODE=1920x1080x32
# #GRUB_GFXMODE=2560x1440x32
# GRUB_GFXMODE=auto
# GRUB_GFXPAYLOAD_LINUX=keep
sudo grub-mkconfig -o /boot/grub/grub.cfg


# --- inicio punk confuguraciones específicas ----------------------------------
# - para prevenir de este error en el journalctl:
# systemd-udevd[315]: could not read from '/sys/module/pcc_cpufreq/initstate': No such device
# sudo modprobe pcc_cpufreq
# --- final punk confuguraciones específicas -----------------------------------

# primera snapshot en btrfs
sudo pacman -S snapper
sudo snapper -c root create-config /; \
sudo snapper -c root create -d "init"; \
sudo snapper -c home create-config /home; \
sudo snapper -c home create -d "init"

sudo reboot

# ejecutar los scripts de instalación de programas incluidos en este repositorio
