export TIMEZONE="Asia/Jakarta"

export HOST_NAME=$(hostnamectl | awk '/Hardware Model/{print $3}')
export USERNAME=""
export ROOT_PASSWORD=""
export USER_PASSWORD=""
export KERNEL=1
export KERNEL_OPTIONS=(linux linux-lts linux-zen)
export BOOTLOADER=1

export EFI_PARTITION=""
export ROOT_PARTITION=""

export SWAP_METHOD=0
export SWAP_PARTITION=""

export CONFIRM_INSTALL=""

clear

timezone() {
    # TODO
    # Add validation
    info "Timezone format are Continent/City"
    info "Default, $TIMEZONE"
    local timezone=$(tzselect)

    if [[ -n "$timezone" ]]; then
        TIMEZONE=$timezone
    fi

    clear
}

hostname() {
    info "Default, $HOST_NAME"
    local host_name=$(input "Enter your hostname")

    if [[ -n "$host_name" ]]; then
        HOST_NAME=$host_name
    fi

    clear
}

kernel() {
    info "Default, ${KERNEL_OPTIONS[(($KERNEL - 1))]}"
    local kernel="$(option "Select kernel" "${KERNEL_OPTIONS[@]}")"

    if [[ -n "$kernel" ]]; then
        KERNEL=$kernel
    fi

    KERNEL=$(("$KERNEL" - 1))

    echo "$KERNEL"

    clear
}

bootloader() {
    info "Default, GRUB"
    local bootloader=$(option "Select the bootloader" "GRUB" "Systemd-boot")

    if [[ -n "$bootloader" ]]; then
        BOOTLOADER=$bootloader
    fi

    clear
}

username() {
    USERNAME=$(input_noempty "Enter your username")
    clear
}

user_password() {
    info "User password cannot be empty"

    USER_PASSWORD=$(input_silent "Enter your User ($USERNAME) password")
    if [[ -z "$USER_PASSWORD" ]]; then
        clear
        warn "Cannot be empty"
        user_password
        return 0
    fi

    echo -e
    password_verification=$(input_silent "Verify your User ($USERNAME) password")

    if [[ "$USER_PASSWORD" != "$password_verification" ]]; then
        clear
        warn "Password doesn't match,"
        user_password
        return 0
    fi

    clear
}

root_password() {
    info "Empty password will disable root user"
    ROOT_PASSWORD=$(input_silent "Enter your Root password")

    if [[ -z "$ROOT_PASSWORD" ]]; then
        clear
        return 0
    fi

    echo -e
    local password_verification=$(input_silent "Verify your root password")

    if [[ "$ROOT_PASSWORD" != "$password_verification" ]]; then
        clear
        warn "Password doesn't match, try again"
        root_password
    fi

    clear
}

efi_partition() {
    local partition=""
    local partition_type=""
    local confirm=""

    list_disk
    echo -e
    info "Type the full path, e.g., /dev/nvme0n1p1"
    info "Make sure this partition is safe to format"
    partition=$(input_noempty "Select your EFI partition")

    if ! blkid "$partition" &>/dev/null; then
        clear
        error "Cannot get partition. format or check the partition"
        efi_partition
        return 0
    fi

    partition_type=$(get_partinfo "type" "$partition")

    if [[ -n "$partition_type" ]]; then
        warn "${partition} is formatted as ${partition_type} and will be erased."
        confirm=$(input_noempty "Confirm? (y/n)")

        if ! [[ "$confirm" =~ [Yy] ]]; then
            clear
            efi_partition
            return 0
        fi
    fi

    EFI_PARTITION="$partition"

    clear
}

root_partition() {
    local partition=""
    local partition_type=""
    local confirm=""

    list_disk
    echo -e
    info "Type the full path e.g., /dev/nvme0n1p2"
    info "Make sure this partition is safe to format"
    partition=$(input_noempty "Select your ROOT partition")

    if ! blkid "$partition" &>/dev/null; then
        clear
        error "Cannot get partition. format or check the partition"
        root_partition
        return 0
    fi

    if [[ "$partition" == "$EFI_PARTITION" ]]; then
        clear
        error "Partition has been used for EFI"
        root_partition
        return 0
    fi

    partition_type=$(get_partinfo "type" "$partition")

    if [[ -n "$partition_type" ]]; then
        warn "${partition} is formatted as ${partition_type} and will be erased."
        confirm=$(input_noempty "Confirm? (y/n)")

        if ! [[ "$confirm" =~ [Yy] ]]; then
            clear
            root_partition
            return 0
        fi
    fi

    ROOT_PARTITION="$partition"

    clear
}

swap() {
    # Show this option only if bootloader is a GRUB
    if [[ $BOOTLOADER -eq 1 ]]; then
        info "This option is optional"
        info "Zram only support GRUB as bootloader"
        info "Empty this option to skip swap"
        SWAP_METHOD=$(option "Choose swap method" "Swap" "Zram")
        clear
    fi
    if [[ -z $SWAP_METHOD ]]; then
        return 0
    fi
    if [[ $SWAP_METHOD -gt 1 ]]; then
        return 0
    fi

    local partition

    SWAP_METHOD=1

    list_disk
    echo -e
    info "Type the full path e.g., /dev/nvme0n1p4"
    info "To us swap file type '/swapfile' to the input"
    info "Empty this option to skip swap"
    partition=$(input "Select your SWAP partition")

    if [[ -z "$partition" ]]; then
        SWAP_METHOD=0
        return 0
    fi

    if [[ "$partition" == "$EFI_PARTITION" ]]; then
        clear
        error "Partition has been used for EFI"
        swap_partition
        return 0
    fi

    if [[ "$partition" == "$ROOT_PARTITION" ]]; then
        clear
        error "Partition has been used for ROOT"
        swap_partition
        return 0
    fi

    if includes_array "$partition" "${EXTRA_STORAGE[@]}"; then
        clear
        error "Partition has been used for extra storage"
        swap_partition
        return 0
    fi

    if ! blkid "$partition" &>/dev/null && ! [[ "$partition" == '/swapfile' ]]; then
        clear
        error "Cannot get partition. format or check the partition"
        swap_partition
        return 0
    fi

    if [[ ${partition} != "/swapfile" ]]; then
        local partition_type=""
        partition_type=$(get_partinfo "type" "$partition")

        if [[ -n "$partition_type" ]]; then
            warn "${partition} is formatted as ${partition_type} and will be erased."
            confirm=$(input_noempty "Confirm? (y/n)")

            if ! [[ "$confirm" =~ [Yy] ]]; then
                clear
                swap_partition
                return 0
            fi
        fi
    fi

    SWAP_PARTITION="$partition"

    clear
}

summary() {
    print_color "$MAGENTA" "Summary: "
    echo -e

    print_color "$GREEN" "Timezone: "
    print_color "$WHITE" "$TIMEZONE"
    echo -e

    print_color "$GREEN" "hostname: "
    print_color "$WHITE" "$HOST_NAME"
    echo -e

    print_color "$GREEN" "User: "
    print_color "$WHITE" "$USERNAME"
    echo -e

    print_color "$GREEN" "Root Password: "
    if [[ -n "$ROOT_PASSWORD" ]]; then
        print_color "$WHITE" "enabled"
    else
        print_color "$WHITE" "disabled"
    fi
    echo -e

    print_color "$GREEN" "User Password: "
    if [[ -n "$USER_PASSWORD" ]]; then
        print_color "$WHITE" "yes"
    else
        print_color "$WHITE" "no"
    fi
    echo -e

    print_color "$GREEN" "EFI Partition: "
    print_color "$WHITE" "$EFI_PARTITION"
    echo -e

    print_color "$GREEN" "ROOT Partition: "
    print_color "$WHITE" "$ROOT_PARTITION"
    echo -e

    print_color "$GREEN" "Swap Method: "
    if [[ "$SWAP_METHOD" -eq "0" ]]; then
        print_color "$WHITE" "Disabled"
    fi
    if [[ "$SWAP_METHOD" -eq "1" ]]; then
        print_color "$WHITE" "Swap"
    fi
    if [[ "$SWAP_METHOD" -eq "2" ]]; then
        print_color "$WHITE" "Zram"
    fi
    echo -e

    if [[ "$SWAP_METHOD" -eq "1" ]]; then
        print_color "$GREEN" "Swap partition: "
        print_color "$WHITE" "$SWAP_PARTITION"
        echo -e
    fi

    print_color "$GREEN" "Kernel: "
    print_color "$WHITE" "${KERNEL_OPTIONS[$KERNEL]}"
    echo -e

    print_color "$GREEN" "Bootloader: "
    if [[ "$BOOTLOADER" -eq "1" ]]; then
        print_color "$WHITE" "GRUB"
    fi
    if [[ "$BOOTLOADER" -eq "2" ]]; then
        print_color "$WHITE" "Systemd-boot"
    fi
    echo -e

    CONFIRM_INSTALL=$(input_noempty "Confirm installation? (y/n)")
}
