#!/bin/bash

packagelist=(
    polari # porque me dió un error en el journal (puede que sin importancia)
    epiphany # el navegador por defecto de gnome que no mola nada
    gnome-documents # no le veo la utildad
    gnome-recipes # no le veo la utildad
    gnome-builder # bloated
    gnome-games # crashea al abrir ¿?
    totem # reproductor de videos de Gnome, no le veo la utilidad
    accerciser
    devhelp
    glade
    gnome-sound-recorder # audacity
    gnome-todo
    gnome-usage # gnome-system-monitor lo substituye
)

pacman -Rns --noconfirm "${packagelist[@]}"
# n: borra archivos de configuración

# equivalente a apt autoremove:
# pacman -Rns $(pacman -Qtdq)
