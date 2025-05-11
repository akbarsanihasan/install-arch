Private_add_loader() {
	local root_id

	root_id=$(get_partinfo "uuid" "$ROOT_PARTITION")

	echo "title   Archlinux" | tee "$ESP_MOUNTPOINT"/loader/entries/archlinux.conf &>/dev/null

	if [[ "$KERNEL" == "1" ]]; then
		tee -a "$ESP_MOUNTPOINT"/loader/entries/archlinux.conf <<-EOF
			linux   /vmlinuz-linux 
			initrd  /initramfs-linux.img
			initrd  /initramfs-linux-fallback.img
		EOF
	fi

	if [[ "$KERNEL" == "2" ]]; then
		tee -a "$ESP_MOUNTPOINT"/loader/entries/archlinux.conf <<-EOF
			linux   /vmlinuz-linux-zen 
			initrd  /initramfs-linux-zen.img
			initrd  /initramfs-linux-zen-fallback.img
		EOF
	fi

	if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
		echo "initrd  /intel-ucode.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
	fi

	if [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
		echo "initrd  /amd-ucode.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
	fi

	echo "options root=UUID=${root_id} rw log_level=3 quiet splash" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
}

grub() {
	clear
	info "Installing grub"

	grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNTPOINT" --boot-directory="$ESP_MOUNTPOINT" --bootloader-id=Archlinux

	local new_options='splash'

	sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=5/' "$ROOT_MOUNTPOINT"/etc/default/grub
	sed -i 's/^#GRUB_DISABLE_OS_PROBER=/GRUB_DISABLE_OS_PROBER=/' "$ROOT_MOUNTPOINT"/etc/default/grub
	sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\([^\"]*\)\".*/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $new_options/" "$ROOT_MOUNTPOINT"/etc/default/grub

	arch-chroot "$ROOT_MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg

	success "Installing grub.\n"
	sleep 3
}

systemd() {
	clear
	info "Installing systemd boot"

	if [ ! -d "$ESP_MOUNTPOINT" ]; then
		error "EFI System Partition (ESP) not found at ${ESP_MOUNTPOINT}. Adjust the mount point."
		exit 0
	fi

	bootctl --esp-path="$ESP_MOUNTPOINT" install

	echo -e "default archlinux*" | tee "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "timeout 5" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "console-mode max" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "default @saved" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null

	mkdir -p "$ROOT_MOUNTPOINT"/etc/pacman.d/hooks
	cp -r ./etc/95-systemd-boot.hook "$ROOT_MOUNTPOINT"/etc/pacman.d/hooks/95-systemd-boot.hook

	Private_add_loader

	success "Systemd-boot installed successfully.\n"
	sleep 3
}

install_bootloader() {
	if [[ "$BOOTLOADER" == "1" ]]; then
		grub
	elif [[ "$BOOTLOADER" == "2" ]]; then
		systemd
	else
		error "INVALID bootloader choice\n"
		error "Bootloader not installed, you won't be able to boot to your Operating System\n"
		exit 1
	fi
}
