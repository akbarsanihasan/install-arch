base_system() {
	clear
	print_color "$MAGENTA" "Installing base systems... \n"
	sleep 3

	BASE_PACKAGE=(base sudo linux-firmware iptables-nft)
	NETWORK_PACKAGE=(networkmanager wpa_supplicant wireless_tools netctl)
	AUDIO=(pipewire pipewire-audio pipewire-pulse pipewire-jack pipewire-alsa wireplumber)
	REFLECTOR_PACKAGE=(reflector pacman-contrib)
	FS_PACKAGE=(ntfs-3g exfatprogs virtiofsd)
	OTHER_PACKAGE=(git vim zsh)

	KERNEL_PACKAGE=()
	if [[ $KERNEL == "1" ]]; then
		KERNEL_PACKAGE=(linux linux-headers)
	elif [[ $KERNEL == "2" ]]; then
		KERNEL_PACKAGE=(linux-zen linux-zen-headers)
	else
		error "Failed to get kernel"
	fi

	BOOTLOADER_PACKAGE=()
	if [[ $BOOTLOADER == "1" ]]; then
		BOOTLOADER_PACKAGE=(grub os-prober efibootmgr dosfstools mtools)
	elif [[ $BOOTLOADER == "2" ]]; then
		BOOTLOADER_PACKAGE=(efibootmgr dosfstools mtools)
	else
		error "Failed to get bootloader"
	fi

	MICROCODE_PACKAGE=()
	if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
		MICROCODE_PACKAGE=(intel-ucode)
	elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
		MICROCODE_PACKAGE=(amd-ucode)
	else
		warning "Unknown cpu, no microcode installed\n"
		sleep 3
	fi

	SWAP_PACKAGE=()
	if [[ "$SWAP_METHOD" == "2" ]]; then
		SWAP_PACKAGE=(zram-generator)
	fi

	MAX_RETRIES=5
	RETRY_COUNT=0

	until pacstrap "$ROOT_MOUNTPOINT" \
		"${BASE_PACKAGE[@]}" \
		"${KERNEL_PACKAGE[@]}" \
		"${MICROCODE_PACKAGE[@]}" \
		"${FS_PACKAGE[@]}" \
		"${SWAP_PACKAGE[@]}" \
		"${NETWORK_PACKAGE[@]}" \
		"${AUDIO[@]}" \
		"${REFLECTOR_PACKAGE[@]}" \
		"${OTHER_PACKAGE[@]}" \
		"${BOOTLOADER_PACKAGE[@]}"; do

		((RETRY_COUNT++))

		if ((RETRY_COUNT >= MAX_RETRIES)); then
			echo -e "\e[31m[ERROR]\e[0m Maximum retries reached. Aborting."
			exit 1
		fi

		clear
		warn "pacstrap failed (attempt $RETRY_COUNT/$MAX_RETRIES). Retrying in 5 seconds..."
		sleep 5
	done

	success "Installing package to root partition"
	sleep 3
}
