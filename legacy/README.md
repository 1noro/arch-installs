# legacy

Scripts antiguos que **ya no se mantienen** y no usan el instalador nuevo:

- `koi/`: ThinkPad X230
- `ghost/`: máquinas virtuales de VirtualBox
- `auto/`: temporizador de systemd que ejecutaba `pacman -Sy` (¡sincronizar sin
  actualizar deja el sistema en un estado no soportado! Para avisar de
  actualizaciones usar `checkupdates`, de `pacman-contrib`)
- `maintenance/`: comandos sueltos

Los scripts de `koi` y `ghost` clonan este repo y buscan rutas `computers/<host>/...`
que ya no existen: para usarlos hay que ajustar las rutas a `legacy/<host>/...`.
Para modernizar uno, basta con crear `hosts/<host>/host.conf`.
