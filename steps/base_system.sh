base_system() {
	clear
	info "Installing base systems"
	sleep 3

	local base=(base sudo linux-firmware git vim zsh)
	local network=(networkmanager wpa_supplicant wireless_tools netctl iptables-nft)
	local pipewire=(pipewire wireplumber pipewire-audio pipewire-pulse pipewire-jack pipewire-alsa)
	local pacman_util=(reflector pacman-contrib)
	local fs_util=(ntfs-3g exfatprogs virtiofsd)

	kernel=()
	if [[ $KERNEL == "1" ]]; then
		kernel=(linux linux-headers)
	fi
	if [[ $KERNEL == "2" ]]; then
		kernel=(linux-zen linux-zen-headers)
	fi

	bootloader=()
	if [[ $BOOTLOADER == "1" ]]; then
		bootloader=(grub os-prober efibootmgr dosfstools mtools)
	fi
	if [[ $BOOTLOADER == "2" ]]; then
		bootloader=(efibootmgr dosfstools mtools)
	fi

	microcode=()
	if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
		microcode=(intel-ucode)
	fi
	if [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
		microcode=(amd-ucode)
	fi

	swap_util=()
	if [[ "$SWAP_METHOD" == "2" ]]; then
		swap_util=(zram-generator)
	fi

	local MAX_RETRIES=5
	local retry_count=0

	until pacstrap "$ROOT_MOUNTPOINT" \
		"${base[@]}" \
		"${kernel[@]}" \
		"${microcode[@]}" \
		"${fs_util[@]}" \
		"${swap_util[@]}" \
		"${network[@]}" \
		"${pipewire[@]}" \
		"${pacman_util[@]}" \
		"${bootloader[@]}"; do

		((RETRY_COUNT++))

		if ((retry_count >= MAX_RETRIES)); then
			error "Maximum retries reached. Aborting."
			exit 1
		fi

		clear
		warn "Pacstrap failed (attempt $retry_count/$MAX_RETRIES). Retrying in 5 seconds..."
		sleep 5
	done

	success "Installing package to root partition"
	sleep 3
}
