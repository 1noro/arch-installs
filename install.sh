#!/usr/bin/env bash
# install.sh — instalador de Arch Linux reproducible. Se ejecuta DESDE EL USB de
# instalación de Arch (archiso), como root, con red.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/main/install.sh) mpu
#
# Hace, en este orden (todas las preguntas se hacen al principio, luego es
# desatendido):
#   1. comprobaciones (UEFI, red, hora)
#   2. detecta el disco, calcula el reparto de particiones y pide confirmación
#   3. particiona (GPT: ESP + swap + btrfs con subvolúmenes), formatea y monta
#   4. pacstrap del sistema base + fstab
#   5. configura el sistema en un chroot (lib/chroot-setup.sh): usuarios, idioma,
#      GRUB, GNOME, paquetes del host, servicios...
#   6. desmonta y (opcionalmente) reinicia
#
# Después del primer arranque: /opt/arch-installs/post-install.sh (AUR, flatpak,
# dotfiles, snapper).

set -Eeuo pipefail

# rama/tag que se descarga cuando se ejecuta vía curl (se puede sobrescribir con --ref
# o con ARCH_INSTALLS_REF)
DEFAULT_REF=main
GITHUB_REPO=1noro/arch-installs

usage() {
    cat <<EOF
Uso: install.sh [opciones] <host>

  <host>            nombre de una carpeta de hosts/ (mpu, punk...)

Opciones:
  --disk /dev/XXX   instalar en este disco en vez de autodetectarlo
  --plan            solo muestra el disco y el reparto de particiones; no toca nada
  --yes             no pedir confirmaciones (contraseñas: ROOT_PASSWORD / USER_PASSWORD)
  --reboot          reiniciar al terminar sin preguntar
  --ref REF         rama o tag del repositorio a descargar (por defecto: $DEFAULT_REF)
  -h, --help        esta ayuda
EOF
}

# -- argumentos ----------------------------------------------------------------------
HOST_ARG="" DISK="" PLAN=0 ASSUME_YES=0 AUTO_REBOOT=0 REF=${ARCH_INSTALLS_REF:-$DEFAULT_REF}
while (($#)); do
    case $1 in
        --disk)   DISK=${2:?falta el dispositivo}; shift 2 ;;
        --plan)   PLAN=1; shift ;;
        --yes|-y) ASSUME_YES=1; shift ;;
        --reboot) AUTO_REBOOT=1; shift ;;
        --ref)    REF=${2:?falta la rama}; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*)       echo "opción desconocida: $1" >&2; usage >&2; exit 2 ;;
        *)        HOST_ARG=$1; shift ;;
    esac
done
[[ -n $HOST_ARG ]] || { usage >&2; exit 2; }

# -- bootstrap: si se ejecuta vía curl, descargamos el repo completo -------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)
if [[ -z $SCRIPT_DIR || ! -f $SCRIPT_DIR/lib/common.sh ]]; then
    echo "==> descargando $GITHUB_REPO@$REF"
    SRC=/tmp/arch-installs
    rm -rf "$SRC" && mkdir -p "$SRC"
    curl -fsSL "https://github.com/$GITHUB_REPO/archive/refs/heads/$REF.tar.gz" \
        | tar -xz -C "$SRC" --strip-components=1
    args=("$HOST_ARG")
    [[ -n $DISK ]] && args=(--disk "$DISK" "${args[@]}")
    ((PLAN)) && args=(--plan "${args[@]}")
    ((ASSUME_YES)) && args=(--yes "${args[@]}")
    ((AUTO_REBOOT)) && args=(--reboot "${args[@]}")
    exec bash "$SRC/install.sh" "${args[@]}"
fi

REPO_DIR=$SCRIPT_DIR
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"
# shellcheck source=lib/disk.sh
source "$REPO_DIR/lib/disk.sh"

trap 'err "falló la línea $LINENO: $BASH_COMMAND"' ERR

# DISK de la línea de comandos tiene prioridad sobre el de la config del host
DISK_CLI=$DISK
load_host "$HOST_ARG"
[[ -n $DISK_CLI ]] && DISK=$DISK_CLI

# -- 1. comprobaciones ------------------------------------------------------------------------
step "Comprobaciones previas ($HOST)"
((PLAN)) || need_root

if ! ((PLAN)); then
    [[ -d /sys/firmware/efi/efivars ]] || die "no has arrancado en modo UEFI (no existe /sys/firmware/efi/efivars)"
    [[ $(cat /sys/firmware/efi/fw_platform_size 2>/dev/null) == 64 ]] \
        || die "el firmware UEFI no es de 64 bits; este instalador solo soporta x86_64-efi"
    have_net || die "sin conexión a internet. Por cable debería ir solo; por wifi usa: iwctl station wlan0 connect <SSID>"
    log "UEFI 64 bits y red: ok"

    timedatectl set-ntp true
    for _ in {1..20}; do
        [[ $(timedatectl show -p NTPSynchronized --value) == yes ]] && break
        sleep 1
    done
    log "hora: $(date '+%F %T %Z')"
fi

# -- 2. disco ---------------------------------------------------------------------------------------
step "Disco y reparto de particiones"
select_disk
disk_plan

if ((PLAN)); then
    log "--plan: no se ha modificado nada"
    exit 0
fi

echo "${C_RED}${C_BLD}¡ATENCIÓN! Se BORRARÁ TODO el contenido de $DISK${C_RST}" >&2
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DISK" >&2 || true
if [[ $ASSUME_YES != 1 ]]; then
    read -r -p "Para continuar escribe el nombre del disco (${DISK##*/}): " answer
    [[ $answer == "${DISK##*/}" ]] || die "cancelado"
fi

# -- contraseñas (todas las preguntas, antes de empezar) -------------------------------------------------
ask_password() {
    local who=$1 p1 p2
    while :; do
        read -r -s -p "Contraseña para $who: " p1; echo >&2
        read -r -s -p "Repítela: " p2; echo >&2
        [[ -n $p1 && $p1 == "$p2" ]] && break
        warn "no coinciden o está vacía"
    done
    printf '%s' "$p1"
}
hash_password() { openssl passwd -6 -stdin <<<"$1"; }

if [[ -n ${ROOT_PASSWORD:-} ]]; then pw=$ROOT_PASSWORD; else pw=$(ask_password root); fi
ROOT_HASH=$(hash_password "$pw")
if [[ -n ${USER_PASSWORD:-} ]]; then pw=$USER_PASSWORD; else pw=$(ask_password "$USERNAME"); fi
USER_HASH=$(hash_password "$pw")
unset pw ROOT_PASSWORD USER_PASSWORD

LOG=/tmp/arch-installs.log
exec > >(tee -a "$LOG") 2>&1
log "registro en $LOG"

# -- 3. particionado, formato, montaje ----------------------------------------------------------------------------
step "Particionando $DISK"
partition_disk
format_and_mount

# -- 4. sistema base ---------------------------------------------------------------------------------------------------
step "Mirrors y pacstrap"
sed -i -E 's/^#?Color/Color/; s/^#?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
if ! reflector --country "$MIRROR_COUNTRIES" --protocol https --age 24 --latest 20 --sort rate \
        --save /etc/pacman.d/mirrorlist; then
    warn "reflector ha fallado; uso los mirrors de respaldo de la configuración"
    { printf 'Server = %s\n' "${MIRRORS_FALLBACK[@]}"; cat /etc/pacman.d/mirrorlist; } >/tmp/mirrorlist.new
    cp /tmp/mirrorlist.new /etc/pacman.d/mirrorlist
fi

cpu_ucode() {
    case $(awk -F': ' '/^vendor_id/ {print $2; exit}' /proc/cpuinfo) in
        GenuineIntel) echo intel-ucode ;;
        AuthenticAMD) echo amd-ucode ;;
    esac
}
mapfile -t BASE_PKGS < <(read_pkglist "$REPO_DIR/packages/base.txt"; cpu_ucode)
log "paquetes base: ${#BASE_PKGS[@]} ($(cpu_ucode || true))"
pacstrap -K "$MNT" "${BASE_PKGS[@]}"
cp /etc/pacman.d/mirrorlist "$MNT/etc/pacman.d/mirrorlist"

step "fstab"
genfstab -U "$MNT" > "$MNT/etc/fstab"
# quitamos subvolid= para que los snapshots/rollbacks de snapper no dependan del número
sed -i -E 's/,subvolid=[0-9]+//' "$MNT/etc/fstab"
if [[ -f $HOST_DIR/fstab.extra ]]; then
    { echo; cat "$HOST_DIR/fstab.extra"; } >> "$MNT/etc/fstab"
fi
cat "$MNT/etc/fstab"

# -- 5. configuración en chroot ---------------------------------------------------------------------------------------------
step "Configurando el sistema (chroot)"
mkdir -p "$MNT/opt/arch-installs"
tar -C "$REPO_DIR" --exclude=.git -cf - . | tar -C "$MNT/opt/arch-installs" -xf -

arch-chroot "$MNT" env \
    HOST="$HOST" ROOT_HASH="$ROOT_HASH" USER_HASH="$USER_HASH" \
    bash /opt/arch-installs/lib/chroot-setup.sh

# resolv.conf lo gestiona systemd-resolved (no se puede enlazar desde dentro del chroot)
ln -sf ../run/systemd/resolve/stub-resolv.conf "$MNT/etc/resolv.conf"

mkdir -p "$MNT/var/log"
cp "$LOG" "$MNT/var/log/arch-installs-install.log"

# -- 6. fin -------------------------------------------------------------------------------------------------------------------------
step "Terminando"
sync
umount -R "$MNT"
[[ -n $P_SWAP ]] && swapoff "$P_SWAP" || true

cat >&2 <<EOF

${C_GRN}${C_BLD}Instalación de $HOST terminada.${C_RST}

  1. Retira el USB y reinicia.
  2. Inicia sesión como ${USERNAME} (GDM).
  3. Abre una terminal y ejecuta:   ${C_BLD}/opt/arch-installs/post-install.sh${C_RST}
     (AUR, flatpak, dotfiles con yadm, snapper)

Registro de la instalación: /var/log/arch-installs-install.log
EOF

if ((AUTO_REBOOT)) || { [[ $ASSUME_YES != 1 ]] && confirm "¿Reiniciar ahora?"; }; then
    reboot
fi
