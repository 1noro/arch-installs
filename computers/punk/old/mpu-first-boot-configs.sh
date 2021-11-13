# punk FIRSTBOOT
# (https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_T470)

# iniciamos sesión como "cosmo"
# su cosmo
# (EL SCRIPT DEPLOY AÚN NO ESTÁ FUNCIONANDO)
mkdir -p ~/Work/github
cd ~/Work/github
git clone https://github.com/1noro/dotfiles.git; \
cd dotfiles; \
bash deploy.sh; \
cd; \
source ~/.bashrc # para recargar el .bashrc sin reiniciar la shell

# si no tenemos .bash_logout (no creo que haga mucha falta)
# cp /etc/skel/.bash_logout ~

# --- configuración de pacman
# copiar el archivo mirrorlist de esta configuración en /etc/pacman.d/mirrorlist
# o generar uno por velocidad como se describe en la wiki:
# https://wiki.archlinux.org/index.php/Mirrors_(Espa%C3%B1ol)#Lista_por_velocidad
sudo nano /etc/pacman.conf
# descomentar las siguientes lineas:
# - en Misc options:
#Color
#VerbosePkgLists
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
sudo pacman -S mesa lib32-mesa # instalar OpenGl y OpenGl 32 (para steam, por ejemplo)
sudo pacman -S jack2 lib32-jack2 xdg-desktop-portal-gtk gnu-free-fonts noto-fonts-emoji gdm gnome gnome-extra
# gdm ya está en el grupo gnome, pero lo escribo para que quede patente
# especifico xdg-desktop-portal-gtk para no tener que leer la wiki siempre
# revisar las diferencias entre xdg-desktop-portal-gtk y xdg-desktop-portal-kde
# especifico jack2 para no tener que leer la wiki siempre
# https://github.com/jackaudio/jackaudio.github.com/wiki/Q_difference_jack1_jack2
sudo systemctl enable gdm


# --- instalando y configurando NetworkManager
# instalamos NetworkManager para poder gestionar la red desde gnome
sudo pacman -S wpa_supplicant wireless_tools networkmanager network-manager-applet gnome-keyring  --needed

# systemctl --type=service
sudo systemctl stop dhcpcd
sudo systemctl disable dhcpcd
sudo pacman -Rns dhcpcd

sudo systemctl enable wpa_supplicant
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


# -- Teaaring Fix (intel graphics)
# parece que no funciona hoy dia; revisar:
# https://wiki.archlinux.org/index.php/GNOME/Troubleshooting#Tear-free_video_with_Intel_HD_Graphics
# https://wiki.archlinux.org/index.php/Intel_graphics_(Espa%C3%B1ol)#Desactivar_Vertical_Synchronization_(VSYNC)
sudo nano /etc/X11/xorg.conf.d/20-intel.conf
# agrega las siguientes lineas:
# Section "Device"
#    Identifier  "Intel Graphics"
#    Driver      "intel"
#    Option      "TearFree"    "true"
# EndSection
sudo nano /home/cosmo/.drirc
# escribir lo siguiente:
# <device screen="0" driver="dri2">
#         <application name="Default">
#                 <option name="vblank_mode" value="0"/>
#         </application>
# </device>
sudo reboot


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
#(parece que ya no hace falta)


# --- inicio mpu confuguraciones específicas ---------------------------------------------
# - para prevenir de este error en el journalctl:
# systemd-udevd[315]: could not read from '/sys/module/pcc_cpufreq/initstate': No such device
sudo modprobe pcc_cpufreq

# --- final mpu confuguraciones específicas ----------------------------------------------

# primera snapshot en btrfs
sudo pacman -S snapper
sudo snapper -c root create-config /
sudo snapper -c root create -d "init"
sudo snapper -c home create-config /home
sudo snapper -c home create -d "init"

sudo reboot

# ejecutar los scripts de instalación de programas incluidos en este repositorio
