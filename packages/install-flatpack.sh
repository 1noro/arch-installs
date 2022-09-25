#!/bin/bash

packagelist=(
    com.getpostman.Postman
    com.github.tchx84.Flatseal
    com.google.Chrome
    io.bassi.Amberol
    org.freedesktop.Platform
    org.freedesktop.Platform.GL.default
    org.freedesktop.Platform.VAAPI.Intel
    org.freedesktop.Platform.openh264
    org.gnome.Platform
    org.gnome.World.Secrets
    org.gtk.Gtk3theme.Adwaita-dark
)

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update
flatpak install --user --assumeyes "${packagelist[@]}"
