#!/bin/bash
# (c) inoro [20200421a]
# [install-from-repositories]

packagelist_install=(
    ## utilidades básicas (no gráficas)
    linux-headers
    lm_sensors
    # zsh
    # zsh-syntax-highlighting
    fish
    nano
    wget
    # net-tools # deprecated (use: ip addr)
    ethtool
    dnsutils
    tree
    # tldr
    htop
    nmap
    iperf3
    neofetch
    git
    rmlint # Limpia home de archivos vacios y enlaces rotos (https://github.com/sahib/rmlint)
    jdk-openjdk # last java
    # jdk11-openjdk # java 11
    perl-file-mimeinfo # Determine file type, includes mimeopen and mimetype
    udisks2 # temperatura de SSD con SMART
    unrar
    inetutils # telnet y mas...
    phonon-qt5-vlc # https://wiki.archlinux.org/index.php/KDE#Phonon (debatir entre GStreamer or VLC)
    pkgstats # https://wiki.archlinux.org/index.php/Pkgstats_(Espa%C3%B1ol)
    nut # Network UPS (SAI) Tools (config: https://wiki.archlinux.org/index.php/Network_UPS_Tools)
    sl # para cuando te equivoques con 'ls'
    cmatrix # cool

    ## utilidades básicas (gráficas)
    firefox
    sxiv # visor de imágenes (complementa a eog)
    # xorg-xkill # (si usas wyland no es necesario)
    simple-scan
    gparted
    easytag
    # gprename # sustituto de pyrenamer
    filezilla
    wireshark-qt
    bleachbit # limpiador de basura
    gnome-tweaks
    papirus-icon-theme
    seahorse # gestor de claves GPG de GNOME
    keepassxc # gestor de contraseñas
    sshfs # montar carpetas a traves de ssh

    ## funcionabilidad total de pulseaudio
    # muchas de estas aplicaciones no vienen instaladas, pero creo que no
    # hacen falta
    alsa-utils
    pulseaudio-alsa
    lib32-libpulse
    lib32-alsa-plugins
    pavucontrol # permite diferenciar mejor que gnome el audio interno del externo
    # puede que haga falta trastear en el ALSAMIXER para que funcione el micro externo

    ## editores de texto
    # gedit
    # geany
    # geany-plugins
    # libreoffice-fresh
    nvim # en modo de prueba
    xclip # for X11 clipboard
    #wl-copy # for WYLAND clipboard

    ## dependencias
    ### gnome shell system monitor extension dependences
    gtop # (debian) gir1.2-gtop-2.0
    # ¿nm-connection-editor? # (debian) gir1.2-nm-1.0
    clutter # (debian) gir1.2-clutter-1.0

    ## reproductores de vídeo y audio
    vlc
    # mpv
    rhythmbox
    # cmus # rhythmbox en la terminal

    ## cliente bittorrent
    qbittorrent

    ## cliente ed2k
    # amule

    ## pdf
    evince
    okular
    # xournalpp

    ## procesamiento de imágenes
    gimp
    inkscape

    ## procesamiento de audio
    audacity

    ## editor de diagramas
    # dia

    ## editor 2D
    librecad

    ## games (https://blends.debian.org/games/tasks/puzzle)
    gnome-mahjongg
    puzzles # https://www.chiark.greenend.org.uk/~sgtatham/puzzles/
    gnome-2048
    gnome-games # virtual boy advance substitute
    # gplanarity

    ## chromium
    # chromium
    # chrome-gnome-shell

    ## latex
    texlive-most
    biber
    # texmaker # substituido por atom o vscode

    ## fuentes extra
    # (https://wiki.archlinux.org/index.php/Fonts_(Espa%C3%B1ol)#Instalaci%C3%B3n)
    noto-fonts-emoji # emoji de Google
    otf-latin-modern # fuentes mejoradas para latex
    otf-latinmodern-math # fuentes mejoradas para latex (matemátias)
    # - Fuentes adobe source han - Una gran colección de fuentes con un soporte
    # comprensible de chino simplificado, chino tradicional, japones, y
    # coreano, con un diseño y aspecto consistente.
    adobe-source-han-sans-otc-fonts # Sans fonts.
    adobe-source-han-serif-otc-fonts # Serif fonts.
    # - Si no gusta lo anterior se pueden instalar de forma separada
    # ttf-baekmuk # fuente coreana
    # ttf-hanazono # fuente japonesa
    # adobe-source-han-sans-cn-fonts # Fuentes de chino simplificado OpenType/CFF Sans.
    # adobe-source-han-sans-tw-fonts # Fuentes de chino tradicional OpenType/CFF Sans.
    # adobe-source-han-serif-cn-fonts # Fuentes de chino simplificado OpenType/CFF Serif.
    # adobe-source-han-serif-tw-fonts # Fuentes de chino tradicional OpenType/CFF Serif.
    # - otros idiomas
    ttf-arphic-uming
    ttf-indic-otf
    # - fuentes monospace preciosas
    # ttf-anonymous-pro # http://www.marksimonson.com/fonts/view/anonymous-pro
    ttf-fira-mono # https://en.wikipedia.org/wiki/Fira_Sans
    otf-fira-mono
    ttf-fira-code # https://github.com/tonsky/FiraCode (en pruebas para usarla en mi terminal por defecto)
    #otf-fira-code # no se encuentra
)

pacman -Syyu
pacman -S --needed ${packagelist_install[@]}
