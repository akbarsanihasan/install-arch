base_system() {
	clear
	info "Installing base systems"
	sleep 3

	local base=(base sudo linux-firmware git vim zsh)
	local network=(networkmanager wpa_supplicant wireless_tools)
	local pacman_util=(reflector pacman-contrib)
	kernel=("${KERNEL_OPTIONS[$KERNEL]}")

	swap_util=()
	if [[ "$SWAP_METHOD" == "2" ]]; then
		swap_util=(zram-generator)
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

	pacstrap "$ROOT_MOUNTPOINT" \
		"${base[@]}" \
		"${kernel[@]}" \
		"${network[@]}" \
		"${microcode[@]}" \
		"${bootloader[@]}" \
		"${swap_util[@]}" \
		"${pacman_util[@]}"

	success "Installing package to root partition"
	sleep 3
}
