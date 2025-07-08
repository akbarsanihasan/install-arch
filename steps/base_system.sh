base_system() {
    clear
    info "Installing base systems"
    sleep 3

    local packages=(
        base
        sudo
        linux-firmware
        networkmanager
        wpa_supplicant
        wireless_tools
        reflector
        pacman-contrib
        efibootmgr
        dosfstools
        mtools
        "${KERNEL_OPTIONS[$KERNEL]}"
    )
    if [[ "$SWAP_METHOD" == "2" ]]; then
        packages+=(zram-generator)
    fi

    if [[ $BOOTLOADER == "1" ]]; then
        packages+=(grub os-prober)
    fi

    if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
        packages+=(intel-ucode)
    fi
    if [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
        packages+=(amd-ucode)
    fi

    pacstrap "$ROOT_MOUNTPOINT" "${packages[@]}"
    success "Installing package to root partition"
    sleep 3
}
