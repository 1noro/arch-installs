#!/bin/bash

set -e

if [[ $(id -u) -eq 0 ]]; then
    echo "This script must be run as a non-root user"
    exit 1
fi

CURRENT_DIR=$(pwd)
AUR_DIR="/opt/aur"

cd "$AUR_DIR"

# -- INICIO DE LA INSTALACIÓN --------------------------------------------------
## Juegos
# openrct2-git
# git clone https://aur.archlinux.org/packages/openrct2-git && \
# cd openrct2-git && \
# makepkg -sri --noconfirm && \
# cd ..

## Navegadores
# google-chrome
git clone https://aur.archlinux.org/google-chrome.git && \
cd google-chrome && \
makepkg -sri --noconfirm && \
cd ..

## Descargas
# jdownloader
git clone https://aur.archlinux.org/jdownloader2.git && \
cd jdownloader2 && \
makepkg -sri --noconfirm && \
cd ..

## VPNs
# # mullvad
# # hay que mirar el PKGBUILD y comprobar que claves se necesitan
# # PKGBUILD: https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mullvad-vpn
# # dónde encontrar las claves: https://mullvad.net/en/help/open-source/
# # gía de mullvad para confiar en las claves: https://mullvad.net/en/help/verifying-signatures/
# # claves necesarias a dia 202004242239
# # EA0A77BF9E115615FC3BD8BC7653B940E494FE87 Linus Färnstrand (code signing key) <linus@mullvad.net>
# # 8339C7D2942EB854E3F27CE5AEE9DECFD582E984 David Lönnhager (code signing) <david.l@mullvad.net>
# # las descargo a mi pc:
# gpg2 --keyserver pool.sks-keyservers.net --recv-keys EA0A77BF9E115615FC3BD8BC7653B940E494FE87
# gpg2 --keyserver pool.sks-keyservers.net --recv-keys 8339C7D2942EB854E3F27CE5AEE9DECFD582E984
# # las edito:
# gpg2 --edit-key EA0A77BF9E115615FC3BD8BC7653B940E494FE87
# # > trust
# # > 5
# # > s
# # > q
# gpg2 --edit-key 8339C7D2942EB854E3F27CE5AEE9DECFD582E984
# # > trust
# # > 5
# # > s
# # > q
# # ya hora puedo instalar el paquete
# git clone https://aur.archlinux.org/mullvad-vpn.git && \
# cd mullvad-vpn && \
# makepkg -sri --noconfirm && \
# sudo systemctl enable mullvad-daemon && \
# cd ..

## Fuentes
# iosevka (https://typeof.net/Iosevka/)
# fuente monospace preciosa
# git clone https://aur.archlinux.org/ttf-iosevka.git && \
# cd ttf-iosevka && \
# makepkg -sri --noconfirm && \
# cd ..

# mononoki (https://madmalik.github.io/mononoki/)
# fuente monospace preciosa
# git clone https://aur.archlinux.org/ttf-mononoki-git.git && \
# cd ttf-mononoki-git && \
# makepkg -sri --noconfirm && \
# cd ..

# ttf-ms-fonts (https://madmalik.github.io/mononoki/)
# Core TTF Fonts from Microsoft, puede que necesaria para alguna apliación
git clone https://aur.archlinux.org/ttf-ms-fonts.git && \
cd ttf-ms-fonts && \
makepkg -sri --noconfirm && \
cd ..

# open-dyslexic-fonts (https://opendyslexic.org/)
git clone https://aur.archlinux.org/open-dyslexic-fonts.git && \
cd open-dyslexic-fonts && \
makepkg -sri --noconfirm && \
cd ..

# adobe-base-14-fonts (Courier, Helvetica, Times, Symbol, ZapfDingbats with Type1)
git clone https://aur.archlinux.org/adobe-base-14-fonts.git && \
cd adobe-base-14-fonts && \
makepkg -sri --noconfirm && \
cd ..

# otf-nerd-fonts-fira-code
git clone https://aur.archlinux.org/otf-nerd-fonts-fira-code.git && \
cd otf-nerd-fonts-fira-code && \
makepkg -sri --noconfirm && \
cd ..

# ttf-twemoji-color
# util para que en mpv aparezcan emojis en los títulos de los vídeos
git clone https://aur.archlinux.org/ttf-twemoji-color.git && \
cd ttf-twemoji-color && \
makepkg -sri --noconfirm && \
cd ..

## Correo electrónico
# protonmail-bridge (se necesita una cuenta de pago)
# git clone https://aur.archlinux.org/protonmail-bridge.git && \
# cd protonmail-bridge && \
# makepkg -sri --noconfirm && \
# cd ..

## Autofirma
# autofirma
# git clone https://aur.archlinux.org/autofirma.git && \
# cd autofirma && \
# makepkg -sri --noconfirm && \
# cd ..

## Packet Tracer
# packettracer
# necesitas el deb de la versión mas actualizada del packet tracer
# descargado desde: https://www.netacad.com/portal/resources/packet-tracer
# git clone https://aur.archlinux.org/packettracer.git && \
# cd packettracer && \
# makepkg -sri --noconfirm && \
# cd ..

## Speedtest by Ookla
# speedtest
# git clone https://aur.archlinux.org/ookla-speedtest-bin.git && \
# cd ookla-speedtest-bin && \
# makepkg -sri --noconfirm && \
# cd ..

## Visual Studio Code (Microsoft Branded)
# (para poder usar Live Share)
# visual-studio-code-bin
git clone https://aur.archlinux.org/visual-studio-code-bin.git && \
cd visual-studio-code-bin && \
makepkg -sri --noconfirm && \
cd ..

## Android Studio: The official Android IDE (Stable branch)
# android-studio
# git clone https://aur.archlinux.org/android-studio.git && \
# cd android-studio && \
# makepkg -sri --noconfirm && \
# cd ..
## PARA REINSTALAR BORRAR TODAS LAS CARPETAS "android", "Google" y "gradle" QUE HAY EN TU $HOME
## ACEPTAR LICENCIAS
## https://stackoverflow.com/questions/54273412/failed-to-install-the-following-android-sdk-packages-as-some-licences-have-not/59981986?newreg=6ef286d40c8543e99181e0db7d0bfdb8
## INSTALA "Android SDK Command-line Tools" DESDE EL SDK MANAGER (interfaz gráfica)
## export JAVA_HOME=/opt/android-studio/jre/
## yes | ~/Android/Sdk/tools/bin/sdkmanager --licenses

## mahjong (https://mahjong.julianbradfield.org/)
# mahjong
# git clone https://aur.archlinux.org/mahjong.git && \
# cd mahjong && \
# makepkg -sri --noconfirm && \
# cd ..

## nut-monitor (https://wiki.archlinux.org/index.php/Network_UPS_Tools#NUT-Monitor)
# nut-monitor (pygtk es una dependencia y parece que no es tan facil instalarla)
# git clone https://aur.archlinux.org/nut-monitor.git && \
# cd nut-monitor && \
# makepkg -sri --noconfirm && \
# cd ..
# DESINSTALAR: sudo pacman -Rns nut-monitor

## rdfind (https://rdfind.pauldreik.se/)
# Redundant data find - a program that finds duplicate files.
# rdfind
# git clone https://aur.archlinux.org/rdfind.git && \
# gpg --keyserver keyserver.ubuntu.com --search-keys 5C4A26CD4CC8C397 \
# cd rdfind && \
# makepkg -sri --noconfirm && \
# cd ..

## lyrebird (https://github.com/lyrebird-voice-changer/lyrebird)
# Simple and powerful voice changer for Linux, written in GTK 3
# lyrebird
# git clone https://aur.archlinux.org/lyrebird.git && \
# cd lyrebird && \
# makepkg -sri --noconfirm && \
# cd ..

## cgoban3 (https://gokgs.com)
# A KGS client and SGF editor (edit Go scenarios)
# cgoban3
# git clone https://aur.archlinux.org/cgoban3.git && \
# cd cgoban3 && \
# makepkg -sri --noconfirm && \
# cd ..


## Apostrophe (https://apps.gnome.org/es/app/org.gnome.gitlab.somas.Apostrophe/)
# Edit Markdown in style
# apostrophe
git clone https://aur.archlinux.org/apostrophe.git && \
cd apostrophe && \
makepkg -sri --noconfirm && \
cd ..

# -- FIN DE LA INSTALACIÓN -----------------------------------------------------

cd "$CURRENT_DIR"
