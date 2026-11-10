#!/usr/bin/env bash
# lib/chroot-setup.sh — configuración del sistema recién instalado. Lo ejecuta
# install.sh dentro de `arch-chroot /mnt`; no hace falta lanzarlo a mano.
#
# Entrada (variables de entorno): HOST, ROOT_HASH, USER_HASH

set -Eeuo pipefail

REPO_DIR=/opt/arch-installs
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"
trap 'err "chroot: falló la línea $LINENO: $BASH_COMMAND"' ERR

need_root
: "${HOST:?}" "${ROOT_HASH:?}" "${USER_HASH:?}"
load_host "$HOST"

# -- pacman -------------------------------------------------------------------------------
configure_pacman() {
    step "pacman"
    sed -i -E 's/^#(Color)$/\1/; s/^#(VerbosePkgLists)$/\1/; s/^#?(ParallelDownloads).*/\1 = 5/' /etc/pacman.conf
    # multilib: descomenta la cabecera [multilib] y el Include que le sigue
    sed -i '/^#\[multilib\]$/,/^#Include/ s/^#//' /etc/pacman.conf
    if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
        # el pacman.conf no trae la sección (p. ej. imágenes recortadas): la añadimos
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
    fi

    mkdir -p /etc/pacman.d/hooks
    cat > /etc/pacman.d/hooks/remove_old_cache.hook <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Cleaning pacman cache...
When = PostTransaction
Exec = /usr/bin/paccache -r
EOF
    pacman -Syu --noconfirm
}

# -- hora, idioma, nombre ------------------------------------------------------------------------
configure_locale() {
    step "hora, idioma y nombre del equipo"
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc || warn "hwclock --systohc ha fallado (se ajustará tras el primer arranque con NTP)"

    local loc
    for loc in "${LOCALES[@]}"; do
        sed -i "s/^#${loc} UTF-8/${loc} UTF-8/" /etc/locale.gen
        grep -q "^${loc} UTF-8" /etc/locale.gen || warn "locale desconocido: $loc"
    done
    locale-gen
    echo "LANG=$LANG_DEFAULT" > /etc/locale.conf
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

    # teclado para GDM / Wayland / Xorg (localectl no funciona dentro de un chroot)
    mkdir -p /etc/X11/xorg.conf.d
    cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "$X11_LAYOUT"
    Option "XkbVariant" "$X11_VARIANT"
EndSection
EOF

    echo "$HOST" > /etc/hostname
    cat > /etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOST.$HOST_DOMAIN	$HOST
EOF
}

# -- usuarios ---------------------------------------------------------------------------------------
configure_users() {
    step "usuarios"
    usermod --password "$ROOT_HASH" root

    if ! id "$USERNAME" &>/dev/null; then
        useradd --create-home --shell "$USER_SHELL" --groups wheel "$USERNAME"
    fi
    usermod --password "$USER_HASH" "$USERNAME"
    create_home_subvols

    # sudo para el grupo wheel (en sudoers.d, sin tocar /etc/sudoers)
    echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
    chmod 440 /etc/sudoers.d/10-wheel
    visudo -cf /etc/sudoers.d/10-wheel >/dev/null

    chown -R "$USERNAME:$USERNAME" /opt/arch-installs
}

# create_home_subvols: carpetas del usuario como subvolúmenes btrfs anidados en @home,
# para que no entren en sus snapshots (ver HOME_SUBVOLS en hosts/defaults.conf)
create_home_subvols() {
    local -a dirs=("${HOME_SUBVOLS[@]}")
    [[ " ${PACKAGE_SETS[*]} " == *" virt "* ]] && dirs+=(.vm)
    [[ " ${PACKAGE_SETS[*]} " == *" gaming "* ]] && dirs+=(.local/share/Steam)
    local d p home=/home/$USERNAME
    for d in "${dirs[@]}"; do
        p=$home/$d
        [[ -e $p ]] && continue
        runuser -u "$USERNAME" -- mkdir -p "${p%/*}"
        btrfs subvolume create "$p" >/dev/null
        chown "$USERNAME:$USERNAME" "$p"
        log "subvolumen ~/$d"
    done
    # imágenes de VM: sin copy-on-write (evita la fragmentación; a cambio, sin checksums)
    if [[ -d $home/.vm ]]; then chattr +C "$home/.vm"; fi
}

# los grupos extra se añaden tras instalar los paquetes (docker, vboxusers... no existen antes)
add_user_groups() {
    local g
    for g in "${USER_GROUPS[@]}"; do
        if getent group "$g" >/dev/null; then
            usermod -aG "$g" "$USERNAME"
        else
            log "grupo '$g' no existe (paquete no instalado): omitido"
        fi
    done
}

# -- paquetes -----------------------------------------------------------------------------------------
# install_official: instala las listas del host. Los paquetes que ya no existan en
# los repos se omiten con un aviso (en vez de abortar toda la instalación).
install_official() {
    step "paquetes de los repositorios oficiales"
    local -a files want avail=() missing=()
    mapfile -t files < <(pkg_files official)
    mapfile -t want < <(read_pkglist "${files[@]}")

    local known p
    known=$({ pacman -Slq; pacman -Sgq; } | sort -u)
    for p in "${want[@]}"; do
        if grep -qxF -- "$p" <<<"$known"; then avail+=("$p"); else missing+=("$p"); fi
    done
    if ((${#missing[@]})); then
        warn "no existen en los repositorios y se omiten: ${missing[*]}"
        printf '%s\n' "${missing[@]}" > /root/packages-missing.txt
    fi
    log "instalando ${#avail[@]} paquetes"
    # ~2000 paquetes: un mirror que corta la descarga no debe tirar la instalación
    local try
    for try in 1 2 3; do
        pacman -S --needed --noconfirm "${avail[@]}" && return 0
        warn "pacman -S ha fallado (intento $try/3); reintento en 10 s"
        sleep 10
    done
    die "no se pudieron instalar los paquetes oficiales"
}

# -- initramfs y arranque -----------------------------------------------------------------------------
configure_boot() {
    step "initramfs y GRUB"

    mkdir -p /etc/mkinitcpio.conf.d
    if ((${#MKINITCPIO_MODULES[@]})); then
        echo "MODULES=(${MKINITCPIO_MODULES[*]})" > /etc/mkinitcpio.conf.d/10-host.conf
    fi
    if ((${#MKINITCPIO_HOOKS[@]})); then
        echo "HOOKS=(${MKINITCPIO_HOOKS[*]})" > /etc/mkinitcpio.conf.d/20-hooks.conf
    fi
    mkinitcpio -P

    # instalación "normal" (entrada en la NVRAM) + copia en la ruta de respaldo
    # EFI/BOOT/BOOTX64.EFI por si la NVRAM se resetea o la placa la ignora
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

    local cmdline="$KERNEL_CMDLINE"
    [[ -n $KERNEL_CMDLINE_EXTRA ]] && cmdline+=" $KERNEL_CMDLINE_EXTRA"
    # hibernación: el hook `resume` (initramfs de busybox) necesita saber cuál es el swap
    local swap_dev
    swap_dev=$(awk '$3 == "swap" && $1 !~ /^#/ {print $1; exit}' /etc/fstab)
    if [[ -n $swap_dev && " ${MKINITCPIO_HOOKS[*]} " == *" resume "* ]]; then
        cmdline+=" resume=$swap_dev"
    fi
    set_kv /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT "\"$cmdline\""
    set_kv /etc/default/grub GRUB_TIMEOUT "$GRUB_TIMEOUT"
    set_kv /etc/default/grub GRUB_TIMEOUT_STYLE menu
    set_kv /etc/default/grub GRUB_DISABLE_RECOVERY true
    set_kv /etc/default/grub GRUB_GFXMODE "$GRUB_GFXMODE"
    set_kv /etc/default/grub GRUB_GFXPAYLOAD_LINUX keep
    # con linux-lts instalado, grub-mkconfig lo pondría primero (orden por nombre):
    # la entrada por defecto debe ser el kernel normal; el LTS queda en "Opciones avanzadas"
    set_kv /etc/default/grub GRUB_TOP_LEVEL '"/boot/vmlinuz-linux"'
    if [[ -f $REPO_DIR/assets/grub-bg.png ]]; then
        install -Dm644 "$REPO_DIR/assets/grub-bg.png" /boot/grub/grub-bg.png
        set_kv /etc/default/grub GRUB_BACKGROUND '"/boot/grub/grub-bg.png"'
    fi
    grub-mkconfig -o /boot/grub/grub.cfg
}

# -- GDM: night light también en la pantalla de login ----------------------------------------------------
configure_gdm() {
    command -v dconf >/dev/null || return 0
    step "GDM (dconf)"
    mkdir -p /etc/dconf/profile /etc/dconf/db/gdm.d
    if [[ ! -f /etc/dconf/profile/gdm ]]; then
        printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' > /etc/dconf/profile/gdm
    elif ! grep -q '^system-db:gdm' /etc/dconf/profile/gdm; then
        sed -i '/^file-db:/i system-db:gdm' /etc/dconf/profile/gdm
    fi
    cat > /etc/dconf/db/gdm.d/10-night-light <<'EOF'
[org/gnome/settings-daemon/plugins/color]
night-light-enabled=true
EOF
    dconf update
}

# -- servicios ----------------------------------------------------------------------------------------------------------------------------------------
enable_services() {
    step "servicios"
    local unit
    for unit in "${SERVICES[@]}"; do
        # pasamos por `systemctl cat`: una unidad inexistente no es un error grave
        if systemctl cat "$unit" &>/dev/null; then
            systemctl enable "$unit"
        else
            warn "unidad no encontrada, omitida: $unit"
        fi
    done
}

# -- overlays (ficheros de configuración que se copian tal cual a /) -----------------------------------------------------------------------------
apply_overlays() {
    step "overlay de ficheros"
    local dir
    for dir in "$REPO_DIR/overlay/common" "$HOST_DIR/overlay"; do
        [[ -d $dir ]] || continue
        # tar en vez de cp -a: no cambia el propietario ni los permisos de los
        # directorios que ya existen (/etc, /usr...) y deja los ficheros como root
        tar -C "$dir" -cf - . | tar -C / -xf - --no-same-owner --no-overwrite-dir
        log "aplicado: ${dir#"$REPO_DIR"/}"
    done
}

# =============================================================================
configure_pacman
configure_locale
configure_users
apply_overlays
install_official
add_user_groups
configure_gdm
configure_boot
enable_services

# gancho específico del host (hardware): hosts/<host>/chroot.sh
if [[ -f $HOST_DIR/chroot.sh ]]; then
    step "ajustes específicos de $HOST"
    # shellcheck source=/dev/null
    source "$HOST_DIR/chroot.sh"
fi

step "chroot terminado"
