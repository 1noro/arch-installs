
# Como indexar musica de una carpeta diferente a Musica en GNOME

https://gitlab.gnome.org/GNOME/gnome-music/-/issues/457

```
xdg-user-dirs-update --set MUSIC /nfs/Music/Beets/
# remove from tracker3
tracker3 index -d /nfs/Music/Beets/
# add recursive to tracker3
tracker3 index -ar /nfs/Music/Beets/
tracker3 status
```
