# hosts/punk/chroot.sh — se carga (source) al final de lib/chroot-setup.sh.
# shellcheck shell=bash

# TLP y power-profiles-daemon (el selector "Modo de energía" de GNOME) se pisan.
# Aquí manda TLP porque es el único que gestiona los umbrales de carga de la batería.
systemctl mask power-profiles-daemon.service
# recomendado por TLP: que systemd no restaure el estado de rfkill por su cuenta
systemctl mask systemd-rfkill.service systemd-rfkill.socket

# --- comprobaciones de hardware opcional del T470 (solo avisan) -------------------
if grep -qs '^0x10de' /sys/bus/pci/devices/*/vendor; then
    warn "este T470 tiene GPU NVIDIA (GeForce 940MX): se usa nouveau por defecto."
    warn "Para el driver propietario: pacman -S nvidia nvidia-prime (no incluido a propósito)."
fi
for _usb in /sys/bus/usb/devices/*/idVendor; do
    if [[ -r $_usb && $(<"$_usb") == 138a ]]; then
        warn "lector de huellas Validity (138a:xxxx) detectado: hace falta libfprint-2-tod1-vfs0090 o python-validity (AUR); no se instala automáticamente."
        break
    fi
done
