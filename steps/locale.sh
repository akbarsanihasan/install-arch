setting_locale() {
	clear
	info "Configuring locale and language"

	local ADDITIONAL_LOCALE="id_ID.UTF-8"

	ln -sf /usr/share/zoneinfo/"$TIMEZONE" "$ROOT_MOUNTPOINT"/etc/localtime
	timedatectl set-ntp true &>/dev/null
	hwclock --systohc &>/dev/null

	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_GB.UTF-8/s/^#//' /etc/locale.gen
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
	arch-chroot "$ROOT_MOUNTPOINT" sed -i "/^#$ADDITIONAL_LOCALE/s/^#//" /etc/locale.gen

	tee "$ROOT_MOUNTPOINT"/etc/locale.conf <<-EOF
		LANG="en_GB.UTF-8"
		LANGUAGE="en_GB.UTF-8"
		LC_CTYPE="$ADDITIONAL_LOCALE"
		LC_COLLATE="$ADDITIONAL_LOCALE"
		LC_MESSAGES="$ADDITIONAL_LOCALE"
		LC_NAME="$ADDITIONAL_LOCALE"
		LC_NUMERIC="$ADDITIONAL_LOCALE"
		LC_TIME="$ADDITIONAL_LOCALE"
		LC_MONETARY="$ADDITIONAL_LOCALE"
		LC_PAPER="$ADDITIONAL_LOCALE"
		LC_ADDRESS="$ADDITIONAL_LOCALE"
		LC_TELEPHONE="$ADDITIONAL_LOCALE"
		LC_MEASUREMENT="$ADDITIONAL_LOCALE"
		LC_IDENTIFICATION="$ADDITIONAL_LOCALE"
	EOF

	arch-chroot "$ROOT_MOUNTPOINT" locale-gen

	success "Successfully setting locale\n"
	sleep 3
}
