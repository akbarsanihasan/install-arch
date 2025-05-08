setting_locale() {
	local ADDITIONAL_LOCALE="id_ID.UTF-8"

	clear
	print_color "$MAGENTA" "Configuring locale and language...\n"

	ln -sf /usr/share/zoneinfo/"$TIMEZONE" "$ROOT_MOUNTPOINT"/etc/localtime
	timedatectl set-ntp true &>/dev/null
	hwclock --systohc &>/dev/null

	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_GB.UTF-8/s/^#//' /etc/locale.gen
	arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
	arch-chroot "$ROOT_MOUNTPOINT" sed -i "/^#$ADDITIONAL_LOCALE/s/^#//" /etc/locale.gen

	echo -e "LANG=\"en_GB.UTF-8\"" | tee "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LANGUAGE=\"en_GB.UTF-8\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_CTYPE=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_COLLATE=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_MESSAGES=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_NAME=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_NUMERIC=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_TIME=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_MONETARY=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_PAPER=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_ADDRESS=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_TELEPHONE=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_MEASUREMENT=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null
	echo -e "LC_IDENTIFICATION=\"$ADDITIONAL_LOCALE\"" | tee -a "$ROOT_MOUNTPOINT"/etc/locale.conf &>/dev/null

	arch-chroot "$ROOT_MOUNTPOINT" locale-gen

	success "Successfully setting locale\n"
	sleep 3
}
