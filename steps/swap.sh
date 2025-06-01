enable_swap() {
	clear
	info "Configuring Swap"

	if check_swap; then
		warn "Swap file or partition already exists"
		exit 0
	fi

	if [[ "$SWAP_PARTITION" == "/swapfile" ]]; then
		local total_ram=$(free -m | awk '/^Mem:/{print $2}')
		local swap_size_default=4096
		local swap_size_half=$((total_ram / 2))
		local swap_size=$swap_size_default

		if [[ $swap_size_half -lt $swap_size_default ]]; then
			swap_size=$swap_size_half
		fi

		arch-chroot "$ROOT_MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" status=progress
		arch-chroot "$ROOT_MOUNTPOINT" chmod 600 "$SWAP_PARTITION"
	fi

	arch-chroot "$ROOT_MOUNTPOINT" mkswap "$SWAP_PARTITION" -f
	arch-chroot "$ROOT_MOUNTPOINT" swapon "$SWAP_PARTITION"

	success "Swap succesfully created"
	sleep 3
}

enable_zram() {
	clear
	info "Configuring zram with zram generator"

	echo "[zram0]" | tee "$ROOT_MOUNTPOINT"/etc/systemd/zram-generator.conf &>/dev/null
	echo "compression-algorithm=zstd" | tee -a "$ROOT_MOUNTPOINT"/etc/systemd/zram-generator.conf &>/dev/null
	echo "swap-priority=100" | tee -a "$ROOT_MOUNTPOINT"/etc/systemd/zram-generator.conf &>/dev/null
	echo "nfs-type=swap" | tee -a "$ROOT_MOUNTPOINT"/etc/systemd/zram-generator.conf &>/dev/null

	arch-chroot "$ROOT_MOUNTPOINT" systemctl daemon-reload
	arch-chroot "$ROOT_MOUNTPOINT" systemctl start /dev/zram0

	success "Zram successfully set\n"
	info "Check zram with zramctl or swapon after reboot\n"
	sleep 3
}

setting_swap() {
	if [[ $SWAP_METHOD == 1 ]]; then
		enable_swap
		return 0
	fi

	if [[ $SWAP_METHOD == 2 ]]; then
		enable_zram
		return 0
	fi
}
