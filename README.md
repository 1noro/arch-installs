# arch-installs

Instalación **reproducible** de Arch Linux para mis equipos: desde el USB de
instalación de Arch hasta el escritorio, con un solo comando. Detecta el disco,
calcula el reparto de particiones y lo deja todo configurado.

| host   | equipo                                                  |
|--------|---------------------------------------------------------|
| `mpu`  | sobremesa: i5-11600K, Radeon RX 580, NVMe, 16 GB        |
| `punk` | ThinkPad T470 (Kaby Lake, Intel HD 620)                 |

> `legacy/` guarda los scripts antiguos de `koi` (ThinkPad X230) y `ghost`
> (VirtualBox), sin mantener. Ver [legacy/README.md](legacy/README.md).

## Uso

### 1. Desde el USB de instalación de Arch (como root, con red)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/main/install.sh) mpu
```

(wifi: `iwctl station wlan0 connect <SSID>` antes de nada.)

Hace las preguntas al principio (confirmar el disco y las contraseñas de `root` y
del usuario) y luego trabaja sin supervisión:

1. comprueba UEFI, red y hora;
2. elige el disco (interno, no extraíble, distinto del USB) y muestra el reparto;
3. particiona, formatea y monta;
4. `pacstrap` + `fstab`;
5. configura todo en un chroot ([`lib/chroot-setup.sh`](lib/chroot-setup.sh)):
   usuario, idioma, GRUB, GNOME, paquetes del host, servicios, ajustes de hardware;
6. desmonta y ofrece reiniciar.

Opciones útiles:

```bash
install.sh --plan mpu               # solo muestra disco y particiones, no toca nada
install.sh --disk /dev/sda mpu      # forzar el disco
install.sh --yes mpu                # sin confirmaciones (ROOT_PASSWORD / USER_PASSWORD en el entorno)
install.sh --ref mi-rama mpu        # descargar otra rama del repo
```

### 2. Tras el primer arranque (como tu usuario)

```bash
/opt/arch-installs/post-install.sh
```

Compila `paru`, instala los paquetes de AUR, los Flatpak, clona los
[dotfiles con yadm](https://github.com/1noro/dotfiles-yadm), configura snapper y
activa los servicios de AUR. Es idempotente: si algo falla se puede relanzar.

## Guía paso a paso

### Preparación (común)

1. Descarga la ISO de [archlinux.org/download](https://archlinux.org/download/) y grábala en un USB (`dd`, Fedora Media Writer, Ventoy...).
2. **Haz copia de lo que quieras conservar**: el instalador borra el disco entero. Lo que no esté en el repo se pierde (`/home`, configuración de NUT, perfiles de red...).
3. Arranca el USB en **modo UEFI** (en la BIOS desactiva CSM/modo legacy; Secure Boot desactivado).
4. En el menú de Arch elige *Arch Linux install medium*. Vas a quedar como `root` en una consola.
5. Distribución de teclado de la consola: el instalador ya arranca en `us`. Para tener teclas muertas (US internacional, como en el sistema instalado): `loadkeys us-acentos`.

### Instalar mpu (sobremesa)

1. Conecta el cable de red (DHCP) y comprueba: `ping -c1 archlinux.org`.
2. Opcional, para ver primero qué hará: `bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/main/install.sh) --plan mpu`
3. Instala:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/main/install.sh) mpu
   ```
   - Si hay varios discos NVMe/SATA, prefiere el NVMe; si sigue habiendo duda te deja elegir. Fuerza uno con `--disk /dev/nvme0n1`.
   - Escribe el nombre del disco (`nvme0n1`) para confirmar el borrado y define las contraseñas de `root` y `cosmo`.
   - Tarda un buen rato: se descargan ~2000 paquetes (GNOME, TeX Live, Steam...).
4. Responde `s` a *¿Reiniciar ahora?*, retira el USB.
5. Entra en GDM como `cosmo`, abre una terminal y ejecuta `/opt/arch-installs/post-install.sh`
   (AUR, flatpak, dotfiles, snapper, Mullvad). Introduce la contraseña de sudo cuando la pida.
6. Reinicia. Pendiente a mano: `/etc/nut/*` (SAI), perfiles de red de NetworkManager y la clave GPG para firmar commits (`.gitconfig` firma por defecto).

### Instalar punk (ThinkPad T470)

1. **BIOS** (F1 al arrancar): *Security → Secure Boot* desactivado; *Startup → UEFI/Legacy Boot* en *UEFI Only*; *Config → Power → Sleep State* en *Linux* si existe. Arranca el USB con F12.
2. **Red**: por cable va solo. Por wifi, en la consola del instalador:
   ```bash
   iwctl
   [iwd]# station wlan0 connect <SSID>
   [iwd]# exit
   ping -c1 archlinux.org
   ```
3. Instala:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/main/install.sh) punk
   ```
   Si el T470 tiene un disco SATA y un NVMe, se prefiere el NVMe (`DISK_PREFER` en `hosts/punk/host.conf`). El swap se ajusta a la RAM del equipo (8 o 16 GB).
4. Reinicia, entra en GDM y ejecuta `/opt/arch-installs/post-install.sh`. El wifi hay que volver a configurarlo en GNOME (el del instalador no se copia).
5. Comprueba la energía: `sudo tlp-stat -b` (umbrales de carga 75/80 en BAT0 y BAT1) y `sudo tlp-stat -s`. Para cargar al 100 % un día de viaje: `sudo tlp fullcharge`. El selector *Modo de energía* de GNOME funciona a través de `tlp-pd` (en lugar de `power-profiles-daemon`, que no se instala).
6. Avisos del instalador (los muestra al final del chroot): GPU NVIDIA 940MX (se usa `nouveau`) y lector de huellas Validity (requiere paquetes de AUR a mano).

### Mientras la rama no esté en `main`

Los comandos anteriores descargan `main`. Para probar la rama de desarrollo:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/1noro/arch-installs/refactor/reproducible-install/install.sh) \
    --ref refactor/reproducible-install mpu
```

### Si algo falla

- Todo queda registrado en `/tmp/arch-installs.log` (en el sistema instalado: `/var/log/arch-installs-install.log`).
- `install.sh` se puede relanzar: desmonta lo anterior y vuelve a particionar.
- Los paquetes oficiales inexistentes se omiten y se listan en `/root/packages-missing.txt`.
- `post-install.sh` es idempotente y al final lista lo que ha fallado (paquetes AUR, flatpak, claves).

## Reparto de discos

GPT/UEFI. Todo se calcula en [`lib/disk.sh`](lib/disk.sh):

| partición | tamaño                                  | uso                         |
|-----------|-----------------------------------------|-----------------------------|
| 1 `EFI`   | 1 GiB                                   | FAT32, montada en `/boot`   |
| 2 `swap`  | = RAM (mín. 2 GiB, máx. 32 GiB)         | swap                        |
| 3 `system`| el resto                                | btrfs con subvolúmenes      |

Subvolúmenes (`compress=zstd:3,noatime`): `@` → `/`, `@home`, `@snapshots` →
`/.snapshots`, `@var_log`, `@var_cache`, `@docker` → `/var/lib/docker`.

## Snapshots

Se configuran en `post-install.sh` (snapper necesita el sistema arrancado):

- **`/` (config `root`)**: `snap-pac` hace un snapshot *pre* y otro *post* en cada
  transacción de pacman (también las de paru). Se guardan los 10 últimos pares, más
  10 pares *importantes* (actualizaciones del kernel y `pacman -Syu`). Sin timeline.
- **`/home` (config `home`)**: timeline cada hora; se conservan 5 horarios y 7 diarios.
- `snapper-timeline.timer` y `snapper-cleanup.timer` crean y limpian los snapshots;
  `cosmo` puede usar `snapper` sin sudo (`ALLOW_USERS`).
- **GRUB**: `grub-btrfsd` añade cada snapshot nuevo al submenú *Arch Linux snapshots*.
  El initramfs lleva el hook `grub-btrfs-overlayfs` (por eso usa `udev` en vez de
  `systemd`): un snapshot arrancado es de solo lectura con una capa en RAM, así que
  el sistema funciona pero los cambios se pierden al reiniciar.
- **Volver a un snapshot**: arranca en él desde GRUB, comprueba que va bien y
  ejecuta `sudo snapper rollback`; reinicia.
- **Aviso**: `/boot` (la ESP, FAT32) no entra en los snapshots. Un snapshot anterior a
  una actualización del kernel arranca con el kernel actual y no encuentra sus
  módulos en `/usr/lib/modules`: sirve para rescatar ficheros o hacer el rollback,
  pero tras el rollback hay que reinstalar el kernel (`sudo pacman -S linux`).

## Estructura

```
install.sh              fase 1 (archiso)
post-install.sh         fase 2 (primer arranque)
lib/
  common.sh             funciones compartidas
  disk.sh               detección de disco, particionado, btrfs
  chroot-setup.sh       configuración dentro del chroot
hosts/
  defaults.conf         valores por defecto de todos los equipos
  <host>/
    host.conf           lo propio del equipo (conjuntos de paquetes, cmdline, servicios...)
    packages.txt        paquetes oficiales extra del host
    packages.aur.txt    paquetes AUR extra del host
    fstab.extra         líneas añadidas al fstab (p. ej. NFS)
    overlay/            ficheros que se copian tal cual a / (modprobe.d, tlp.d...)
    chroot.sh           gancho en el chroot (hardware)
    post-install.sh     gancho tras el primer arranque
packages/
  <set>.txt             paquetes oficiales por conjunto (base, gnome, cli, dev, apps, media, gaming, printing, virt)
  <set>.aur.txt         paquetes AUR del conjunto
  flatpak.txt           aplicaciones Flatpak
  gpg-keys.txt          claves PGP que piden los PKGBUILD de AUR
assets/                 fondo de GRUB y fondos de pantalla
docs/                   notas sueltas
legacy/                 koi, ghost y scripts antiguos
```

## Añadir un equipo nuevo

1. `mkdir hosts/<nombre>` y crea `host.conf` (copia el de `mpu` o `punk`).
2. Elige `PACKAGE_SETS` y añade `packages.txt`, `overlay/`, etc. solo si hacen falta.
3. `./install.sh --plan <nombre>` en una máquina cualquiera para ver el reparto.

Las listas `*.txt` admiten comentarios con `#` y varios nombres por línea.

## Decisiones y cosas a revisar

- **Bootloader:** GRUB (con `grub-btrfs` para arrancar snapshots y el fondo `assets/grub-bg.png`).
- **Sin cifrado de disco.**
- **Red:** NetworkManager desde el pacstrap (se acabó instalar `dhcpcd` para quitarlo después).
- **Idioma:** `gl_ES.UTF-8` (es lo que tiene `mpu` hoy; los scripts antiguos ponían `es_ES`). Cambiar `LANG_DEFAULT` en `hosts/defaults.conf`.
- **Paquetes que no existen** en los repos se omiten con aviso y quedan en `/root/packages-missing.txt` en vez de abortar la instalación.
- **NUT (SAI):** el paquete se instala pero su configuración (`/etc/nut/*`, con credenciales) no está en el repo.
- **Redes de NetworkManager** (`CASA`, `DMZ`...) no se migran; hay que volver a crearlas.
