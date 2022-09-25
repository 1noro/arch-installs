#!/bin/bash

packagelist=(
    # Necesidades de Flatpack
    org.gtk.Gtk3theme.Adwaita-dark
    com.github.tchx84.Flatseal

    # Web
    com.getpostman.Postman
    com.google.Chrome

    # GNOME Circle
    io.bassi.Amberol
    # org.gnome.gitlab.somas.Apostrophe
    org.gnome.World.Secrets

    # Bases de datos
    flathub io.dbeaver.DBeaverCommunity
)

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update
flatpak install --user --assumeyes "${packagelist[@]}"
