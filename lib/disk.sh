#!/usr/bin/env bash
# lib/disk.sh — detección del disco, particionado, formateo y montaje (archiso).
# Se usa con `source` después de lib/common.sh y de load_host.
#
# Esquema resultante (GPT, UEFI):
#   p1  ESP_SIZE_MIB   EFI System   FAT32  label EFI     -> /boot
#   p2  swap (auto)    Linux swap          label swap
#   p3  resto          Linux x86-64 root   btrfs, label $FS_LABEL
#                       con los subvolúmenes de BTRFS_SUBVOLS

GUID_ESP=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
GUID_SWAP=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
GUID_ROOT=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709

MNT=${MNT:-/mnt}

# part_path <disco> <n>: /dev/sda -> /dev/sda1 ; /dev/nvme0n1 -> /dev/nvme0n1p1
part_path() {
    local disk=$1 n=$2
    if [[ $disk =~ [0-9]$ ]]; then echo "${disk}p${n}"; else echo "${disk}${n}"; fi
}

# -- detección -------------------------------------------------------------------------

# installer_disk: disco del que ha arrancado el instalador (para no borrarlo)
installer_disk() {
    local src
    src=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
    [[ -n $src ]] || return 0
    lsblk -no PKNAME "$src" 2>/dev/null | awk 'NF {print "/dev/" $1; exit}' || true
}

# candidate_disks: discos internos instalables, uno por línea: "/dev/x|tamaño-bytes|modelo"
#   excluye: no-disks (loop, rom, zram), extraíbles/USB, el medio de instalación y
#   discos de menos de 20 GiB.
candidate_disks() {
    local skip line NAME TYPE SIZE RM TRAN MODEL
    skip=$(installer_disk)
    while IFS= read -r line; do
        eval "$line"   # lsblk -P: NAME="" TYPE="" SIZE="" RM="" TRAN="" MODEL=""
        [[ $TYPE == disk ]] || continue
        [[ $RM == 0 ]] || continue
        [[ $TRAN != usb ]] || continue
        [[ $NAME != "$skip" ]] || continue
        (( SIZE >= 20 * 1024 ** 3 )) || continue
        printf '%s|%s|%s\n' "$NAME" "$SIZE" "${MODEL:-?}"
    done < <(lsblk -dnpbP -o NAME,TYPE,SIZE,RM,TRAN,MODEL)
}

human_size() { numfmt --to=iec-i --suffix=B "$1"; }

# select_disk: fija DISK (respeta DISK ya definido; si no, autodetecta o pregunta)
select_disk() {
    if [[ -n ${DISK:-} ]]; then
        [[ -b $DISK ]] || die "$DISK no es un dispositivo de bloques"
        return
    fi

    local -a cands=() view=()
    mapfile -t cands < <(candidate_disks)
    ((${#cands[@]})) || die "no encuentro ningún disco interno válido. Usa: install.sh --disk /dev/xxx"

    if ((${#cands[@]} > 1)) && [[ -n $DISK_PREFER ]]; then
        local -a pref=()
        local c
        for c in "${cands[@]}"; do
            [[ $c =~ $DISK_PREFER ]] && pref+=("$c")
        done
        ((${#pref[@]})) && cands=("${pref[@]}")
    fi

    if ((${#cands[@]} == 1)); then
        DISK=${cands[0]%%|*}
        return
    fi

    local i f1 f2 f3
    for i in "${!cands[@]}"; do
        IFS='|' read -r f1 f2 f3 <<<"${cands[$i]}"
        view+=("$f1  $(human_size "$f2")  $f3")
    done
    echo "Hay varios discos candidatos:" >&2
    PS3="Elige el disco donde instalar: "
    select choice in "${view[@]}"; do
        [[ -n ${choice:-} ]] && { DISK=${choice%% *}; break; }
    done
}

# swap_gib: tamaño de swap (GiB) según SWAP_SIZE_GIB y la RAM
swap_gib() {
    if [[ $SWAP_SIZE_GIB != auto ]]; then echo "$SWAP_SIZE_GIB"; return; fi
    local kb gib
    kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    gib=$(( (kb + 1048575) / 1048576 ))        # redondeo hacia arriba
    (( gib < 2 )) && gib=2
    (( gib > SWAP_MAX_GIB )) && gib=$SWAP_MAX_GIB
    echo "$gib"
}

# disk_plan: calcula SWAP_GIB y valida que todo cabe; imprime el esquema
disk_plan() {
    local disk_bytes esp_mib swap total_mib root_mib
    disk_bytes=$(blockdev --getsize64 "$DISK" 2>/dev/null || lsblk -dnbo SIZE "$DISK")
    total_mib=$(( disk_bytes / 1048576 ))
    esp_mib=$ESP_SIZE_MIB
    swap=$(swap_gib)
    # en discos pequeños el swap no puede comerse el sistema: máx. 1/4 del disco
    if (( swap * 1024 > total_mib / 4 )); then
        swap=$(( total_mib / 4 / 1024 ))
        warn "disco pequeño: swap reducido a ${swap}G"
    fi
    root_mib=$(( total_mib - esp_mib - swap * 1024 - 2 ))   # 2 MiB: GPT + alineación
    (( root_mib >= 10 * 1024 )) || die "el disco es demasiado pequeño (quedarían ${root_mib} MiB para el sistema)"
    SWAP_GIB=$swap

    local model
    model=$(lsblk -dno MODEL "$DISK" 2>/dev/null | sed 's/ *$//' || true)
    cat >&2 <<EOF

  Disco:  $DISK  ($(human_size "$disk_bytes")${model:+, $model})
  ─────────────────────────────────────────────────────────────
  1  EFI    $(human_size $((esp_mib * 1048576)))  FAT32  /boot
  2  swap   ${swap:-0}G$( ((swap == 0)) && echo ' (sin swap)')
  3  ${FS_LABEL}  $(human_size $((root_mib * 1048576)))  btrfs  (compress=${BTRFS_OPTS#*compress=})
EOF
    local sv
    for sv in "${BTRFS_SUBVOLS[@]}"; do
        printf '       %-12s -> %s\n' "${sv%%:*}" "${sv#*:}" >&2
    done
    echo >&2
}

# -- ejecución -------------------------------------------------------------------------------

# sfdisk_script: script de particionado según SWAP_GIB / ESP_SIZE_MIB
sfdisk_script() {
    echo "label: gpt"
    echo "size=${ESP_SIZE_MIB}MiB, type=$GUID_ESP, name=\"EFI\""
    if (( SWAP_GIB > 0 )); then
        echo "size=${SWAP_GIB}GiB, type=$GUID_SWAP, name=\"swap\""
    fi
    echo "type=$GUID_ROOT, name=\"$FS_LABEL\""
}

# part_numbers: fija P_ESP, P_SWAP (vacío si no hay) y P_ROOT
part_numbers() {
    P_ESP=$(part_path "$DISK" 1)
    if (( SWAP_GIB > 0 )); then
        P_SWAP=$(part_path "$DISK" 2)
        P_ROOT=$(part_path "$DISK" 3)
    else
        P_SWAP=""
        P_ROOT=$(part_path "$DISK" 2)
    fi
}

# release_disk: desmonta todo lo que cuelgue de /mnt y desactiva swap del disco
release_disk() {
    umount -R "$MNT" 2>/dev/null || true
    swapoff -a 2>/dev/null || true
}

partition_disk() {
    release_disk
    log "borrando firmas y creando tabla de particiones GPT en $DISK"
    wipefs --all --force "$DISK" >/dev/null
    sfdisk_script | sfdisk --quiet --wipe always --wipe-partitions always "$DISK"
    partprobe "$DISK" 2>/dev/null || true
    udevadm settle
    part_numbers
    local p
    for p in "$P_ESP" $P_SWAP "$P_ROOT"; do
        local t=0
        until [[ -b $p ]]; do
            sleep 0.5; ((++t > 20)) && die "no aparece la partición $p"
        done
    done
}

format_and_mount() {
    local opts=$BTRFS_OPTS sv name mp

    log "formateando"
    mkfs.fat -F32 -n EFI "$P_ESP" >/dev/null
    if [[ -n $P_SWAP ]]; then
        mkswap --label swap "$P_SWAP" >/dev/null
        swapon "$P_SWAP"
    fi
    mkfs.btrfs --force --label "$FS_LABEL" "$P_ROOT" >/dev/null

    log "creando subvolúmenes btrfs"
    mount "$P_ROOT" "$MNT"
    for sv in "${BTRFS_SUBVOLS[@]}"; do
        btrfs subvolume create "$MNT/${sv%%:*}" >/dev/null
    done
    umount "$MNT"

    log "montando"
    # primero la raíz...
    for sv in "${BTRFS_SUBVOLS[@]}"; do
        name=${sv%%:*} mp=${sv#*:}
        [[ $mp == / ]] && mount -o "subvol=$name,$opts" "$P_ROOT" "$MNT"
    done
    # ...luego el resto de subvolúmenes y por último la ESP en /boot
    for sv in "${BTRFS_SUBVOLS[@]}"; do
        name=${sv%%:*} mp=${sv#*:}
        [[ $mp == / ]] && continue
        mount --mkdir -o "subvol=$name,$opts" "$P_ROOT" "$MNT$mp"
    done
    mount --mkdir -o umask=0077 "$P_ESP" "$MNT/boot"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DISK" >&2 || true
}
