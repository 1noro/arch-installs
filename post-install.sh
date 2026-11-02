#!/usr/bin/env bash
# post-install.sh — segunda fase. Ejecutar tras el primer arranque, con tu usuario
# (NO como root), con red:
#
#   /opt/arch-installs/post-install.sh
#
# Hace: paru → paquetes AUR → flatpak → dotfiles (yadm) → snapper → servicios
# de AUR. Es idempotente: si algo falla (típico: un paquete AUR que no compila) se
# puede volver a lanzar y solo reintenta lo que falte.

set -Eeuo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"
trap 'err "falló la línea $LINENO: $BASH_COMMAND"' ERR

need_user
HOST=$(< /etc/hostname)
load_host "$HOST"
FAILED=()

step "post-install de $HOST"
have_net || die "sin conexión a internet"
sudo -v
# mantener el ticket de sudo vivo mientras dura el script
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
trap 'kill %1 2>/dev/null || true' EXIT

# -- paru ----------------------------------------------------------------------------------------------
install_paru() {
    command -v paru &>/dev/null && return
    step "paru (ayudante de AUR)"
    local tmp
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    ( cd "$tmp/paru-bin" && makepkg -si --noconfirm )
    rm -rf "$tmp"
}

import_gpg_keys() {
    local key
    for key in $(read_pkglist "$REPO_DIR/packages/gpg-keys.txt"); do
        gpg --list-keys "$key" &>/dev/null && continue
        gpg --keyserver keyserver.ubuntu.com --recv-keys "$key" \
            || { warn "no se pudo importar la clave $key"; FAILED+=("gpg:$key"); }
    done
}

# -- AUR: uno a uno para que un fallo no tire abajo al resto ---------------------------------------------------------
install_aur() {
    step "paquetes AUR"
    local -a files pkgs
    mapfile -t files < <(pkg_files aur)
    mapfile -t pkgs < <(read_pkglist "${files[@]}")
    log "${#pkgs[@]} paquetes"
    local p
    for p in "${pkgs[@]}"; do
        pacman -Qq "$p" &>/dev/null && continue
        log "AUR: $p"
        paru -S --needed --noconfirm --skipreview "$p" || { warn "falló: $p"; FAILED+=("aur:$p"); }
    done
}

# -- rust ---------------------------------------------------------------------------------------------------------------
setup_rust() {
    command -v rustup &>/dev/null || return 0
    rustup show active-toolchain &>/dev/null || rustup default stable
}

# -- flatpak ------------------------------------------------------------------------------------------------------------------
install_flatpak() {
    command -v flatpak &>/dev/null || return 0
    step "flatpak"
    local -a files apps
    mapfile -t files < <(pkg_files flatpak)
    mapfile -t apps < <(read_pkglist "${files[@]}")
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    local a
    for a in "${apps[@]}"; do
        flatpak info --user "$a" &>/dev/null && continue
        flatpak install --user --noninteractive -y flathub "$a" \
            || { warn "falló flatpak: $a"; FAILED+=("flatpak:$a"); }
    done
    # los flatpak/portales a veces cambian el navegador por defecto
    xdg-settings set default-web-browser firefox.desktop 2>/dev/null || true
}

# -- dotfiles (yadm) ----------------------------------------------------------------------------------------------------------------------
setup_dotfiles() {
    command -v yadm &>/dev/null || { warn "yadm no está instalado"; return 0; }
    [[ -d $HOME/.local/share/yadm/repo.git ]] && { log "dotfiles: ya clonados"; return 0; }
    step "dotfiles (yadm)"
    # ficheros de /etc/skel que chocarían con los del repositorio
    rm -f "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_logout"
    yadm clone --no-bootstrap "$DOTFILES_URL"
    yadm remote set-url --push origin git@github.com:1noro/dotfiles-yadm.git
    yadm status --short || true

    # neovim: vim-plug + plugins (init.vim usa plug#begin)
    if grep -qs 'plug#begin' "$HOME/.config/nvim/init.vim"; then
        curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        nvim --headless +PlugInstall +qall || warn "PlugInstall ha fallado"
    fi
}

# -- snapper: sigue la guía de la wiki para un subvolumen @snapshots separado --------------------------------------------------------------------
setup_snapper() {
    command -v snapper &>/dev/null || return 0
    step "snapper"
    if ! sudo snapper list-configs 2>/dev/null | grep -q '^root '; then
        # create-config falla si /.snapshots existe; lo recreamos después con el subvolumen @snapshots
        sudo umount /.snapshots 2>/dev/null || true
        sudo rmdir /.snapshots 2>/dev/null || true
        sudo snapper -c root create-config /
        sudo btrfs subvolume delete /.snapshots
        sudo mkdir /.snapshots
        sudo mount -a
        sudo chmod 750 /.snapshots
        sudo snapper -c root create -d "recién instalado (/)"
    fi
    if ! sudo snapper list-configs 2>/dev/null | grep -q '^home '; then
        sudo snapper -c home create-config /home
        sudo snapper -c home create -d "recién instalado (/home)"
    fi
    # que GRUB muestre los snapshots
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# -- servicios de paquetes AUR --------------------------------------------------------------------------------------------------------------------------
enable_post_services() {
    local unit
    for unit in "${POST_SERVICES[@]}"; do
        if systemctl cat "$unit" &>/dev/null; then
            sudo systemctl enable --now "$unit" || warn "no se pudo activar $unit"
        else
            warn "unidad no encontrada (¿falló su paquete AUR?): $unit"
        fi
    done
}

install_paru
import_gpg_keys
install_aur
setup_rust
install_flatpak
setup_dotfiles
enable_post_services
setup_snapper

# gancho específico del host
if [[ -f $HOST_DIR/post-install.sh ]]; then
    step "post-install específico de $HOST"
    # shellcheck source=/dev/null
    source "$HOST_DIR/post-install.sh"
fi

# -- este repositorio, para poder editarlo ------------------------------------------------------------------------------------------------------------------------
if [[ ! -d $HOME/repos/arch-installs/.git ]]; then
    mkdir -p "$HOME/repos"
    if git clone "$REPO_URL.git" "$HOME/repos/arch-installs"; then
        git -C "$HOME/repos/arch-installs" remote set-url --push origin git@github.com:1noro/arch-installs.git
    else
        warn "no se pudo clonar $REPO_URL"
    fi
fi

step "resumen"
if ((${#FAILED[@]})); then
    warn "elementos que han fallado (vuelve a lanzar el script cuando quieras):"
    printf '   - %s\n' "${FAILED[@]}" >&2
else
    log "todo correcto. Ya puedes borrar /opt/arch-installs (sudo rm -rf /opt/arch-installs)."
fi
if sudo test -f /root/packages-missing.txt; then
    warn "paquetes oficiales que no existían durante la instalación: $(sudo cat /root/packages-missing.txt | tr '\n' ' ')"
fi
log "reinicia para aplicar todo."
