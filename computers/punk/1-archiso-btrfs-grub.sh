# punk btrfs (GRUB) ARCHISO
# LEER: https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install#Our_partition_plans

# -- comprobación de red DHCP (por cable)
ping archlinux.org

# -- activamos el servidor SSH y configuramos una contraseña para root
# por si queremos realizar la instalación de forma remota
systemctl start sshd
passwd
ip addr

# -- verificamos que entramos en modo UEFI
ls /sys/firmware/efi/efivars

# -- activamos el servidor ntp para la hora
timedatectl set-ntp true
timedatectl status # (verificación)

# -- inicio del particionado y formateo de los HDDs ----------------------------
lsblk

# - tabla de particiones GPT (systemd-boot)
# https://wiki.archlinux.org/index.php/EFI_system_partition#GPT_partitioned_disks
# https://fhackts.wordpress.com/2016/09/09/installing-archlinux-the-efisystemd-boot-way/
# https://gtronick.github.io/ALIG/
# NAME            SIZE  TYPE                    MOUNTPOINT
# nvme0n1       931,5G  disk
#   nvme0n1p1   512,0M  part EFI System (ESP)   /boot
#   nvme0n1p2    16,0G  part                    [SWAP]
#   nvme0n1p3   914,0G  part                    /

fdisk /dev/nvme0n1
# comandos de fdisk:
# m (listamos la ayuda)
# g (generamos una tabla GPT)
# n (creamos nvme0n1p1)
# t (se selecciona automaticamente la única particion creada)
# 1 (cambiamos el tipo a EFI System)
# n (creamos nvme0n1p2)
# n (creamos nvme0n1p3)
# p (mostramos cómo va a quedar el resultado)
# w (escribimos los cambios y salimos)

lsblk -fm
mkfs.fat -F32 -n EFI /dev/nvme0n1p1
mkswap -L swap /dev/nvme0n1p2
swapon -L swap
mkfs.btrfs --force --label system /dev/nvme0n1p3 # nótese que aquí asignamos el nombre "system" a nuestra partición

# definimos las variables "o" y "o_btrfs" para las opciones de montaje
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime

# montamos nuestra partición "system" en /mnt
mount -t btrfs LABEL=system /mnt

# creamos los subvolumes btrfs
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
#btrfs subvolume create /mnt/snapshots # puede que en el futuro si uso snapper esto no haga falta

# desmontamos todo
umount -R /mnt

# y ahora montamos los sobvolumenes en su orden correspondiente
mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
#mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/.snapshots # puede que en el futuro si uso snapper esto no haga falta

# montamos la partición EFI
mkdir /mnt/boot
mount LABEL=EFI /mnt/boot
lsblk -fm

# -- instalamos el sistema base en el disco particionado (pensar en que
# paquetes son necesarios aquí desde el principio)
# nano /etc/pacman.d/mirrorlist
# agregar al principio de todo las lineas:
# Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch
# Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch
sed -i '1 i\Server = http://mirror.librelabucm.org/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
sed -i '1 i\Server = http://ftp.rediris.es/mirror/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
pacman -Syy # refrescamos los repositorios al cambiar el mirrorlist
pacstrap /mnt base base-devel linux linux-firmware dosfstools exfat-utils btrfs-progs e2fsprogs ntfs-3g man-db man-pages texinfo sudo git nano zsh

# - este mensaje es completamente normal mientras no generemos los locales
# perl: warning: Setting locale failed.
# perl: warning: Please check that your locale settings:
# 	LANGUAGE = (unset),
# 	LC_ALL = (unset),
# 	LC_MESSAGES = "",
# 	LANG = "en_US.UTF-8"
#     are supported and installed on your system.
# perl: warning: Falling back to the standard locale ("C").

# -- generamos el fstab tal cual como lo tenemos montado en la instalación
# genfstab -U /mnt > /mnt/etc/fstab # Use UUIDs for source identifiers
genfstab -L /mnt > /mnt/etc/fstab # Use labels for source identifiers

# -- nos impersonamos como root en nuestro sistema de archivos a instalar
arch-chroot /mnt
# CHROOT MODE

# asignamos una contrseña a root
passwd

# creamos y configuramos un nuevo usuario para podrer instalar paquetes desde AUR
useradd -s /bin/zsh -m cosmo # considerar quitar la opción -m (create_home)
passwd cosmo
# usermod -a -G sudo cosmo
# --- inicio sudo manual ---
env EDITOR=nano visudo
# agregar la siguiente linea:
# cosmo ALL=(ALL) ALL
# --- fin sudo manual ---

# Si recreamos /home/cosmo manualmente hay que ejecutar:
# chown cosmo:cosmo /home/cosmo # considerar poner -R
# si no creamos /home/cosmo manualmente es recomendable ajustar los permisos:
# chmod 755 /home/cosmo
# (AHORA USA DOCKER PUTO)

# instalamos, habilitamos y ejecutamos ssh para poder continuar con la
# instalación desde otro pc de forma remota
pacman -S openssh
systemctl enable sshd

# configuramos la hora (no se porqué esto no funcinó bien la primera vez y
# luego tuve que volver a configurarlo desde gnome)
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# configuramos el idioma por defecto del equipo
# nano /etc/locale.gen
# descomentamos:
# en_US.UTF-8 UTF-8
# es_ES.UTF-8 UTF-8
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i '/es_ES.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo 'LANG=es_ES.UTF-8' > /etc/locale.conf

# ponemos nombre al equipo
echo 'punk' > /etc/hostname
# nano /etc/hosts
# - agregar las siguientes lineas
echo '127.0.0.1	localhost' >> /etc/hosts; \
echo '::1		localhost' >> /etc/hosts; \
echo '127.0.1.1	punk.jamaica.h.a3do.net	punk' >> /etc/hosts

# instalamos y habilitamos el demonio más básico de dhcp para que al reiniciar
# no nos quedemos sin internet
pacman -S dhcpcd
systemctl enable dhcpcd

# --- módulos de kernel necesarios
# agregamos el módulo i915 al kernel de Linux y lo volvemos a configurar
# esto es para cargar KMS lo antes posible al inicio del boot
# https://wiki.archlinux.org/index.php/Kernel_mode_setting_(Espa%C3%B1ol)
#
# *Corrección: esto es para que el módulo de los gráficos de intel (i915) se 
# incorpore al initramfs para que se cargue con el primer arranque del kernel.
# Y se compile automáticamente al actualizar el kernel con pacaman.
# nano /etc/mkinitcpio.conf
# modificar la linea MODULES=() --> MODULES=(i915)
sed -i 's/MODULES=()/MODULES=(i915)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
# comprobar aquí si falta algún módulo por cargar para este hardware específico

# --- INICIO DE COMANDOS EXCLUSIVOS PARA PUNK ----------------------------------
# (https://gist.github.com/imrvelj/c65cd5ca7f5505a65e59204f5a3f7a6d)
# solución para los warnings:
# ==> WARNING: Possibly missing firmware for module: aic94xx
# ==> WARNING: Possibly missing firmware for module: wd719x
su cosmo
mkdir -p ~/Work/aur
cd ~/Work/aur

git clone https://aur.archlinux.org/aic94xx-firmware.git; \
cd aic94xx-firmware; \
makepkg -sri; \
cd ..

git clone https://aur.archlinux.org/wd719x-firmware.git; \
cd wd719x-firmware; \
makepkg -sri; \
cd ..

# según los foros esto no es necesario, pero a mi me funciona para quitar el 
# WARNING al recompilar los módulos dinámicos del nucleo.
# ==> WARNING: Possibly missing firmware for module: xhci_pci
git clone https://aur.archlinux.org/upd72020x-fw.git; \
cd upd72020x-fw; \
makepkg -sri; \
cd ..

exit
mkinitcpio -p linux # volvemos a generar el initramfs en /boot

# --- FINAL DE COMANDOS EXCLUSIVOS PARA PUNK -----------------------------------

# --- GESTOR DE ARRANQUE DEL SISTEMA -------------------------------------------

# instalamos y habilitamos las actualizacionse tempranas de microcodigo
# para procesadores intel
pacman -S intel-ucode

# -- instalación y configuración inicial de GRUB
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# https://wiki.archlinux.org/index.php/Kernel_parameters_(Espa%C3%B1ol)
# https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
# https://wiki.archlinux.org/index.php/Improving_performance#Watchdogs
# https://wiki.archlinux.org/index.php/Intel_graphics#Enable_early_KMS
# nano /etc/default/grub
# editando la linea GRUB_CMDLINE_LINUX_DEFAULT para dejarla así:
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 nowatchdog i915.enable_guc=2"
sed -i 's/loglevel=3 quiet/loglevel=4 nowatchdog i915.enable_guc=2/g' /etc/default/grub
# de paso, también reducimos el tiempo de espera en la pantalla de grub
# GRUB_TIMEOUT=2
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


# --- FIN GESTOR DE ARRANQUE DEL SISTEMA ---------------------------------------

# salimos del entorno chroot, y volvemos al instalador de arch (archiso)
exit
# BACK TO ARCHISO

# desmontamos con seguridad el entorno de instalación
sync; \
umount -R /mnt

# reiniciamos
reboot

# extraemos el medio de instalación (USB o CD/DVD)

# continuar con los pasos de punk-first-boot-configs.sh
