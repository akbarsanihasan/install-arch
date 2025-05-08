enable_swap() {
	clear
	print_color "$MAGENTA" "Configuring Swap...\n"

	TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
	SWAP_SIZE_DEFAULT=4096
	SWAP_SIZE_HALF=$((TOTAL_RAM / 2))
	SWAP_SIZE=$SWAP_SIZE_DEFAULT

	if check_swap; then
		print_color "$YELLOW" "Swap file or partition already exists.\n"
		exit 0
	fi

	if [[ "$SWAP_PARTITION" == "/swapfile" ]]; then
		if [[ "$HIBERNATION" =~ [Yy] ]]; then
			SWAP_SIZE=$TOTAL_RAM
		elif [[ $SWAP_SIZE_HALF -lt $SWAP_SIZE_DEFAULT ]]; then
			SWAP_SIZE=$SWAP_SIZE_HALF
		fi

		arch-chroot "$ROOT_MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count="$SWAP_SIZE" status=progress
		arch-chroot "$ROOT_MOUNTPOINT" chmod 600 "$SWAP_PARTITION"
	fi

	arch-chroot "$ROOT_MOUNTPOINT" mkswap "$SWAP_PARTITION" -f
	arch-chroot "$ROOT_MOUNTPOINT" swapon "$SWAP_PARTITION"

	success "Swap succesfully created\n"
	sleep 3
}

enable_zram() {
	clear
	print_color "$MAGENTA" "Configuring zram with zram generator...\n"

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
	if [[ $SWAP_METHOD == "1" ]]; then
		enable_swap || true
	elif [[ $SWAP_METHOD == "2" ]]; then
		enable_zram
	else
		warn "INVALID SWAP choice, no swap configured\n"
		warn "Cannot setting hibernation\n"
	fi
}
