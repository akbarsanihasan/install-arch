setting_network() {
	clear
	print_color "$MAGENTA" "Configuring network...\n"

	echo "$HOST_NAME" | tee "$ROOT_MOUNTPOINT"/etc/hostname &>/dev/null

	echo -e "127.0.0.1 localhost" | tee "$ROOT_MOUNTPOINT"/etc/hosts &>/dev/null
	echo -e "::1 localhost " | tee -a "$ROOT_MOUNTPOINT"/etc/hosts &>/dev/null
	echo -e "127.0.0.1 $HOST_NAME" | tee -a "$ROOT_MOUNTPOINT"/etc/hosts &>/dev/null

	arch-chroot "$ROOT_MOUNTPOINT" systemctl enable NetworkManager

	success "setting network\n"
	sleep 3
}
