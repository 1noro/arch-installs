#!/bin/bash

# intento de instalar los paquetes mencionados en la lista packages-extra.md

# --- instalación desde los repositorios oficiales de Arch Linux
packagelist_install=(
    ## Edtitores de código e IDEs
    # atom
    # hunspell-es_es # necesario para el paquete spell-check (https://atom.io/packages/spell-check)
    # code # visual studio code (sin las movidas de microsoft)

    ## Juegos
    # hace falta instalar lib32-mesa (para procesadores intel) del repositorio
    # multilib para steam
    ttf-liberation # dependencia para steam
    steam # check diference between steam-native-runtime
    # mgba-sdl
    # 0ad
    # openttd
    openra
    # lutris
    lib32-openssl-1.0 # necesidades para Civilization VI
    # gnugo # juega al GO con una interfaz ASCII por defecto

    ## astronomía
    stellarium

    ## Navegadores
    # firefox-developer-edition

    ## Chats y voideoconferencias
    telegram-desktop
    discord

    ## Máquinas virtuales
    virtualbox-host-modules-arch # para el kernel versión linux de arch
    virtualbox

    ## Emular Windows (necesitas habilitar el repositorio multilib en pacman.conf)
    # wine
    # winetricks

    # Conectar con Android (dispositivos móviles)
    kdeconnect

    # Entornos de programación extra
    # - Haskell
    # ghc
    # cabal-install
    # happy
    # alex
    # haskell-haddock-library
    # stack

    # - GO
    go

    # - Rust
    rustup
    # rustup default stable (comando adicional)

    # - C
    # gdb

    # Extras de Arch Linux
    pacgraph # visualización gráfica de los paquetes y dependencias de pacman

    # Servidor de impresión
    cups
    foomatic-db-engine
    foomatic-db
    foomatic-db-ppds
    foomatic-db-nonfree
    foomatic-db-nonfree-ppds
    gutenprint
    foomatic-db-gutenprint-ppds
    ghostscript
    gsfonts
    avahi

    # Drivers de impresión
    hplip # HP LaserJet Pro M148fdw

    # Browser
    # torbrowser-launcher

    # Conversor de archivos
    pandoc # (markdown > pdf, markdown > HTML, etc)

    # Emuladores de terminal
    cool-retro-term
    # xterm

    # Dependencias opcionales de gdk-pixbuf2 (revisar si siguen siendo necesarias)
    libopenraw # Load .dng, .cr2, .crw, .nef, .orf, .pef, .arw, .erf, .mrw, and .raf
    webp-pixbuf-loader # Load .webp
)

pacman -Syyu
pacman -S --needed ${packagelist_install[@]}

## Comandos adicionales
# VirtualBox
usermod -a -G vboxusers $USER
systemctl enable --now org.cups.cupsd.service
systemctl enable --now avahi-daemon.service

# Rust
rustup default stable
