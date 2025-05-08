setting_pacman() {
	clear
	print_color "$MAGENTA" "Configuring reflector...\n"

	mkdir -p "$ROOT_MOUNTPOINT"/etc/xdg/reflector

	echo -e "--score 32" | tee "$ROOT_MOUNTPOINT"/etc/xdg/reflector/reflector.conf
	echo -e "--protocol https" | tee -a "$ROOT_MOUNTPOINT"/etc/xdg/reflector/reflector.conf
	echo -e "--sort rate" | tee -a "$ROOT_MOUNTPOINT"/etc/xdg/reflector/reflector.conf
	echo -e "--save /etc/pacman.d/mirrorlist" | tee -a "$ROOT_MOUNTPOINT"/etc/xdg/reflector/reflector.conf

	echo -e "[Unit]" | tee "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "Description=Refresh Pacman mirrorlist weekly with Reflector.\n" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "[Timer]" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "OnCalendar=weekly" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "Persistent=true" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "AccuracySec=1us" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "RandomizedDelaySec=12h\n" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "[Install]" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer
	echo -e "WantedBy=timers.target" | tee -a "$ROOT_MOUNTPOINT"/usr/lib/systemd/system/reflector.timer

	arch-chroot "$ROOT_MOUNTPOINT" systemctl enable reflector.timer

	arch-chroot "$ROOT_MOUNTPOINT" cp /etc/pacman.conf /etc/pacman.conf.bak
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]\+/s/^#//' /etc/pacman.conf
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#Color/s/^#//' /etc/pacman.conf
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

	arch-chroot "$ROOT_MOUNTPOINT" cp /etc/makepkg.conf /etc/makepkg.conf.bak
	arch-chroot "$ROOT_MOUNTPOINT" sed -i "s/^#MAKEFLAGS=\".*\"/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf

	print_color "$GREEN" "Configuring reflector\n"
	sleep 3
}
