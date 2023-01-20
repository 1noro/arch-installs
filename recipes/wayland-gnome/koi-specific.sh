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


# -- Batería (muy interesante, pero debería comprobar su correcto funcionamiento)
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
