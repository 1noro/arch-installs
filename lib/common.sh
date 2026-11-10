#!/usr/bin/env bash
# lib/common.sh — funciones compartidas por install.sh, chroot-setup.sh y
# post-install.sh. Se usa con `source`, no se ejecuta.

# REPO_DIR: raíz del repositorio (donde está install.sh)
REPO_DIR=${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}

# -- salida --------------------------------------------------------------------
if [[ -t 2 ]]; then
    C_RED=$'\e[31m' C_GRN=$'\e[32m' C_YLW=$'\e[33m' C_BLU=$'\e[34m' C_BLD=$'\e[1m' C_RST=$'\e[0m'
else
    C_RED='' C_GRN='' C_YLW='' C_BLU='' C_BLD='' C_RST=''
fi

step() { printf '\n%s%s::%s %s%s%s\n' "$C_BLU" "$C_BLD" "$C_RST" "$C_BLD" "$*" "$C_RST" >&2; }
log()  { printf '%s==>%s %s\n' "$C_GRN" "$C_RST" "$*" >&2; }
warn() { printf '%s==> AVISO:%s %s\n' "$C_YLW" "$C_RST" "$*" >&2; }
err()  { printf '%s==> ERROR:%s %s\n' "$C_RED" "$C_RST" "$*" >&2; }
die()  { err "$*"; exit 1; }

need_root() { [[ $EUID -eq 0 ]] || die "este script hay que ejecutarlo como root"; }
need_user() { [[ $EUID -ne 0 ]] || die "este script hay que ejecutarlo como usuario normal (no root)"; }

# confirm "pregunta": respuesta afirmativa si ASSUME_YES=1 o el usuario escribe s/y
confirm() {
    [[ ${ASSUME_YES:-0} == 1 ]] && return 0
    local ans
    read -r -p "$1 [s/N] " ans
    [[ $ans =~ ^[sSyY]$ ]]
}

# have_net: hay salida a internet (no solo DNS)
have_net() { curl -fsS --max-time 8 -o /dev/null https://archlinux.org; }

# -- host ----------------------------------------------------------------------
# load_host <nombre>: carga hosts/<nombre>/host.conf sobre los valores por defecto
load_host() {
    HOST=$1
    HOST_DIR="$REPO_DIR/hosts/$HOST"
    [[ -f "$HOST_DIR/host.conf" ]] || die "no existe la configuración del host '$HOST' ($HOST_DIR/host.conf)"
    # shellcheck source=/dev/null
    source "$REPO_DIR/hosts/defaults.conf"
    # shellcheck source=/dev/null
    source "$HOST_DIR/host.conf"
}

# -- listas de paquetes ----------------------------------------------------------
# read_pkglist <ficheros...>: nombres de paquete, sin comentarios ni vacíos ni duplicados
read_pkglist() {
    local f
    for f in "$@"; do
        # `|| continue` y no `&&`: si el último fichero no existe, el bucle devolvería 1
        # y con pipefail toda la tubería fallaría (salta el trap ERR aunque la lista esté bien)
        [[ -f $f ]] || continue
        sed 's/#.*//' "$f"
    done | tr -s '[:space:]' '\n' | sed '/^$/d' | awk '!seen[$0]++'
}

# pkg_files <sufijo>: ficheros de paquetes de los PACKAGE_SETS y del host
#   sufijo vacío -> repos oficiales (<set>.txt); "aur" -> <set>.aur.txt; "flatpak"
pkg_files() {
    local kind=$1 set
    case $kind in
        official)
            for set in "${PACKAGE_SETS[@]}"; do echo "$REPO_DIR/packages/$set.txt"; done
            echo "$HOST_DIR/packages.txt" ;;
        aur)
            for set in "${PACKAGE_SETS[@]}"; do echo "$REPO_DIR/packages/$set.aur.txt"; done
            echo "$HOST_DIR/packages.aur.txt" ;;
        flatpak)
            echo "$REPO_DIR/packages/flatpak.txt"
            echo "$HOST_DIR/flatpak.txt" ;;
    esac
}

# -- edición de ficheros de configuración ------------------------------------------
# set_kv <fichero> <CLAVE> <valor>: deja `CLAVE=valor` (reemplaza la línea activa,
# o la comentada, o la añade al final). Pensado para /etc/default/grub y similares.
set_kv() {
    local file=$1 key=$2 value=$3 esc
    esc=$(printf '%s' "$value" | sed -e 's/[\\&|]/\\&/g')
    if grep -qE "^${key}=" "$file"; then
        sed -i -E "s|^${key}=.*|${key}=${esc}|" "$file"
    elif grep -qE "^#[[:space:]]*${key}=" "$file"; then
        sed -i -E "0,/^#[[:space:]]*${key}=.*/s||${key}=${esc}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}
