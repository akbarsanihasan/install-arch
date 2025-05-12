setting_pacman() {
	clear
	info "Configuring pacman"

	mkdir -p "$ROOT_MOUNTPOINT"/etc/xdg/reflector

	cp -r ./etc/reflector.conf "$ROOT_MOUNTPOINT"/etc/reflector.conf

	cp -r ./etc/reflector.timer "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	arch-chroot "$ROOT_MOUNTPOINT" systemctl enable reflector.timer

	arch-chroot "$ROOT_MOUNTPOINT" cp /etc/pacman.conf /etc/pacman.conf.bak
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]\+/s/^#//' /etc/pacman.conf
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#Color/s/^#//' /etc/pacman.conf
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

	print_color "$GREEN" "Configuring reflector\n"
	sleep 3
}
