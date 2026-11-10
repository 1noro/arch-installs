# hosts/punk/chroot.sh — se carga (source) al final de lib/chroot-setup.sh.
# shellcheck shell=bash

# power-profiles-daemon no se instala: tlp-pd (servicio activado en host.conf) ofrece
# la misma API D-Bus sobre TLP, así que el selector de GNOME sigue funcionando.
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
