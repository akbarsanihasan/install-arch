setting_network() {
	clear
	info "Configuring network"

	echo "$HOST_NAME" | tee "$ROOT_MOUNTPOINT"/etc/hostname &>/dev/null

	tee "$ROOT_MOUNTPOINT"/etc/hosts <<-EOF
		127.0.0.1 localhost 
		::1 localhost  
		127.0.0.1 $HOST_NAME 
	EOF

	arch-chroot "$ROOT_MOUNTPOINT" systemctl enable NetworkManager

	success "setting network\n"
	sleep 3
}
