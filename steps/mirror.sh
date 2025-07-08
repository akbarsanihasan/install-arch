setting_mirror() {
	echo -e
	info "Configuring pacman and reflector"
        pacman -S --noconfirm reflector
	if [[ ! -e /etc/pacman.d/mirrorlist.bak ]]; then
		cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	fi

	reflector --verbose --latest 5 \
		--protocol https --sort rate \
		--save /etc/pacman.d/mirrorlist

	if [[ ! -e /etc/pacman.conf.bak ]]; then
		cp /etc/pacman.conf /etc/pacman.conf.bak
	fi

	sed -i '/^#ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]\+/s/^#//' /etc/pacman.conf
	sed -i '/^#Color/s/^#//' /etc/pacman.conf
	sed -i '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

	pacman-key --init && pacman-key --populate
	pacman -Sy
	sleep 3
}
