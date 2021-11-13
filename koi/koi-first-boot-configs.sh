# koi FIRSTBOOT

# --- configuración de pacman
# copiar el archivo mirrorlist de esta configuración en /etc/pacman.d/mirrorlist
# o generar uno por velocidad como se describe en la wiki:
# https://wiki.archlinux.org/index.php/Mirrors_(Espa%C3%B1ol)#Lista_por_velocidad
nano /etc/pacman.conf
# descomentar las siguientes lineas:
# - en Misc options:
#Color
#VerbosePkgLists
# - en los repositorios:
#[multilib]
#Include = /etc/pacman.d/mirrorlist
pacman -Syu # actualizamos el sistema
pacman -S pacman-contrib

# agregamos el hook (trigger) para limpiar la cache de pacman
# https://wiki.archlinux.org/index.php/Pacman_(Espa%C3%B1ol)#Limpiar_la_memoria_cach%C3%A9_de_los_paquetes
mkdir -p /etc/pacman.d/hooks/
nano /etc/pacman.d/hooks/remove_old_cache.hook
# - Escribe lo siguiente:
# [Trigger]
# Operation = Upgrade
# Operation = Install
# Operation = Remove
# Type = Package
# Target = *
#
# [Action]
# Description = Cleaning pacman cache...
# When = PostTransaction
# Exec = /usr/bin/paccache -r

# --- instalando los gráficos
lspci | grep VGA
pacman -S xf86-video-intel # driver de la tarjeta grafica
pacman -S mesa lib32-mesa # instalar OpenGl y OpenGl 32 (para steam, por ejemplo)
pacman -S jack2 lib32-jack2 xdg-desktop-portal-gtk gnu-free-fonts gdm gnome gnome-extra
# gdm ya está en el grupo gnome, pero lo escribo para resaltarlo
# especifico xdg-desktop-portal-gtk para no tener que leer la wiki siempre
# revisra las diferencias entre xdg-desktop-portal-gtk y xdg-desktop-portal-kde
# especifico jack2 para no tener que leer la wiki siempre
# https://github.com/jackaudio/jackaudio.github.com/wiki/Q_difference_jack1_jack2
systemctl enable gdm


# --- instalando y configurando NetworkManager
# instalamos NetworkManager para poder gestionar la red desde gnome
pacman -S wpa_supplicant wireless_tools networkmanager network-manager-applet gnome-keyring --needed

# systemctl --type=service
systemctl stop dhcpcd
systemctl disable dhcpcd
# ¿se puede eliminar ahora el paquete dhcpcd?

systemctl enable wpa_supplicant
systemctl enable NetworkManager

# add cosmo to network group
gpasswd -a cosmo network


# --- instalando y configurando el Bluetooth (en caso de estar presente en el equipo)
pacman -S bluez bluez-utils bluez-tools --needed
# verificamos que el modulo btusb está cargado en el kernel
lsmod | grep btusb
systemctl enable bluetooth

# reiniciamos para que se apliquen todos estos cambios importantes
reboot


# instalamos un navegador de internet decente
pacman -S firefox
# configuramos firefox para evitar el tearing forzando la aceleración por hardware
# https://www.muylinux.com/2020/08/26/firefox-80/


# -- Teaaring Fix (intel graphics)
# parece que no funciona hoy dia; revisar:
# https://wiki.archlinux.org/index.php/GNOME/Troubleshooting#Tear-free_video_with_Intel_HD_Graphics
# https://wiki.archlinux.org/index.php/Intel_graphics_(Espa%C3%B1ol)#Desactivar_Vertical_Synchronization_(VSYNC)
nano /etc/X11/xorg.conf.d/20-intel.conf
# agrega las siguientes lineas:
# Section "Device"
#    Identifier  "Intel Graphics"
#    Driver      "intel"
#    Option      "TearFree"    "true"
# EndSection
nano /home/cosmo/.drirc
# escribir lo siguiente:
# <device screen="0" driver="dri2">
#         <application name="Default">
#                 <option name="vblank_mode" value="0"/>
#         </application>
# </device>
reboot


# -- SSD (optimizar y aumentar su vida)
# To verify TRIM support, run:
lsblk --discard
# And check the values of DISC-GRAN (discard granularity) and DISC-MAX (discard
# max bytes) columns. Non-zero values indicate TRIM support.
systemctl enable fstrim.timer


# -- default MIME types
# para que funcione la opción ver en carpeta de los programas como firefox, etc
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# -- agregamos un fondo para que el gurb quede to chulo:
cp /home/cosmo/Work/github/gnu-linux-configs/archlinux/grub-bg.png /boot/grub/grub-bg.png
nano /etc/default/grub
# descomentamos y editamos la linea:
# GRUB_BACKGROUND="/boot/grub/grub-bg.png"
grub-mkconfig -o /boot/grub/grub.cfg

# --- start ThinkPad X230 specific configs -------------------------------------
# (https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X230#Configuration)
# (https://www.reddit.com/r/thinkpad/wiki/os/linux#wiki_which_linux_distro.3F)

# pacman -S xorg-xrandr # me parece que al usar gnome ya no hace falta
# X230 has IPS or TN screen with 125.37 DPI. Refer to HiDPI page for more
# information. It can be set with command xrandr --dpi 125.37 using .xinitrc,
# .xsession or other autostarts.

# --- TouchPad (mejora de experiencia pensada para el modelo X230 y sus iguales)
nano /etc/X11/xorg.conf.d/50-synaptics.conf
# Escribir
# Section "InputClass"
#         Identifier "touchpad"
#         MatchProduct "SynPS/2 Synaptics TouchPad"
#         # MatchTag "lenovo_x230_all"
#         Driver "synaptics"
#         # fix touchpad resolution
#         Option "VertResolution" "100"
#         Option "HorizResolution" "65"
#         # disable synaptics driver pointer acceleration
#         Option "MinSpeed" "1"
#         Option "MaxSpeed" "1"
#         # tweak the X-server pointer acceleration
#         Option "AccelerationProfile" "2"
#         Option "AdaptiveDeceleration" "16"
#         Option "ConstantDeceleration" "16"
#         Option "VelocityScale" "20"
#         Option "AccelerationNumerator" "30"
#         Option "AccelerationDenominator" "10"
#         Option "AccelerationThreshold" "10"
# 	# Disable two fingers right mouse click
# 	Option "TapButton2" "0"
#         Option "HorizHysteresis" "100"
#         Option "VertHysteresis" "100"
#         # fix touchpad scroll speed
#         Option "VertScrollDelta" "500"
#         Option "HorizScrollDelta" "500"
# EndSection


# -- Batería (muy interesante, pero deberí comprobar su correcto funcionamiento)
# (https://www.reddit.com/r/thinkpad/wiki/os/linux#wiki_use_of_ssd_with_linux)
# realmente no se para que sirve el powertop mas que para hacer estadisticas,
# lo que si parece util es el tlp
pacman -S acpi_call powertop

powertop --calibrate

nano /etc/systemd/system/powertop.service
# agregar las siguientes lineas
# [Unit]
# Description=Powertop tunings
#
# [Service]
# Type=idle
# ExecStart=/usr/bin/powertop --auto-tune
#
# [Install]
# WantedBy=multi-user.target

systemctl enable powertop
systemctl start powertop
powertop

pacman -S tlp

nano /etc/mkinitcpio.conf
# modificar la linea MODULES=(i915) --> MODULES=(i915 acpi_call)
mkinitcpio -p linux

nano /etc/default/tlp
# agregar las lineas:
# TLP_ENABLE=1
# MAX_LOST_WORK_SECS_ON_BAT=15
# START_CHARGE_THRESH_BAT0=67
# STOP_CHARGE_THRESH_BAT0=90

# estos dos comandos definen el porcentaje al que se inicia/para de cargar la
# bateria se borran cada vez que esta se extrae
# ejemplo: si el 100% actual es del 60% del origial, un 80% de ese 60% cortaría
# la carga al 51% aprox
# echo 40 > /sys/class/power_supply/BAT0/charge_start_threshold # (probar correcto funcionamiento)
echo 85 > /sys/class/power_supply/BAT0/charge_start_threshold # creo que esta es la configuración lógica
# sospecho de un bug en el comportamiento en charge_start_threshold; si lo
# pones en 40 y el portatiel está a 41 no continua cargando
# echo 80 > /sys/class/power_supply/BAT0/charge_stop_threshold # (probar correcto funcionamiento)
echo 90 > /sys/class/power_supply/BAT0/charge_stop_threshold # creo que esta es la configuración lógica
systemctl enable tlp
reboot

tlp-stat # ver la configuración actual y el estado de la batería

git clone https://aur.archlinux.org/tlpui-git.git
cd tlpui-git
makepkg -sri
cd ..


# -- Ventiladores (optimización pensda exclusivamente para el model x230)
pacman -S lm_sensors
git clone https://aur.archlinux.org/thinkfan.git
cd thinkfan
makepkg -sri
cd ..
# run as ROOT
echo "options thinkpad_acpi fan_control=1" > /etc/modprobe.d/thinkfan.conf
nano /etc/thinkfan.conf
# --- agrega las siguiente lineas (mi configuración):
# tp_fan /proc/acpi/ibm/fan
# hwmon /sys/class/thermal/thermal_zone0/temp
#
# (0, 0,  42)
# (1, 40, 47)
# (2, 45, 52)
# (3, 50, 57)
# (4, 55, 62)
# (5, 60, 77)
# (7, 73, 32767)

# --- otra configuración para /etc/thinkfan.conf
# tp_fan /proc/acpi/ibm/fan
# hwmon /sys/class/thermal/thermal_zone0/temp
#
# (0, 0,  40)
# (1, 53, 65)
# (2, 55, 66)
# (3, 57, 68)
# (4, 61, 70)
# (5, 64, 71)
# (7, 68, 32767)
modprobe thinkpad_acpi
reboot

cat /proc/acpi/ibm/fan
thinkfan -n # testing the configuration
systemctl enable thinkfan

# --- finish ThinkPad X230 specific configs ------------------------------------

reboot

# ejecutar los scripts de instalación de programas incluidos en esta carpeta
