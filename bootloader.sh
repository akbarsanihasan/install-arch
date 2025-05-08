_add_loaders() {
	local root_id

	root_id=$(get_partinfo "uuid" "$ROOT_PARTITION")

	echo "title   Archlinux" | tee "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
	if [[ "$KERNEL" == "1" ]]; then
		echo "linux   /vmlinuz-linux" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
		echo "initrd  /initramfs-linux.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
		echo "initrd  /initramfs-linux-fallback.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux-fallback.conf" &>/dev/null
	elif [[ "$KERNEL" == "2" ]]; then
		echo "linux   /vmlinuz-linux-zen" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
		echo "initrd  /initramfs-linux-zen.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
		echo "initrd  /initramfs-linux-zen-fallback.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux-fallback.conf" &>/dev/null
	else
		error "Failed to get kernel"
	fi

	if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
		echo "initrd  /intel-ucode.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
	elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
		echo "initrd  /amd-ucode.img" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
	else
		print_color "$YELLOW" "Unknown cpu, no microcode installed\n"
	fi

	echo "options root=UUID=${root_id} rw log_level=3 quiet splash" | tee -a "${ESP_MOUNTPOINT}/loader/entries/archlinux.conf" &>/dev/null
}

grub() {
	clear
	print_color "$MAGENTA" "Installing grub...\n"

	local existing_options
	local new_options
	local root_id

	existing_options=$(grep "GRUB_CMDLINE_LINUX_DEFAULT" "$ROOT_MOUNTPOINT"/etc/default/grub | grep -oP '(?<=\")[^\"]+(?=\")')
	new_options="GRUB_CMDLINE_LINUX_DEFAULT=\"$existing_options splash\""
	root_id=$(get_partinfo "uuid" "$ROOT_PARTITION")

	grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNTPOINT" --boot-directory="$ESP_MOUNTPOINT" --bootloader-id=Archlinux

	sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=5/' "$ROOT_MOUNTPOINT"/etc/default/grub
	sed -i 's/^#GRUB_DISABLE_OS_PROBER=/GRUB_DISABLE_OS_PROBER=/' "$ROOT_MOUNTPOINT"/etc/default/grub
	sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${new_options}|" "$ROOT_MOUNTPOINT"/etc/default/grub

	arch-chroot "$ROOT_MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg

	success "Installing grub.\n"
	sleep 3
}

systemd() {
	clear
	print_color "$MAGENTA" "Installing systemd boot...\n"

	if [ ! -d "$ESP_MOUNTPOINT" ]; then
		error "EFI System Partition (ESP) not found at ${ESP_MOUNTPOINT}. Adjust the mount point."
		exit 0
	fi

	mkdir -p "$ROOT_MOUNTPOINT"/etc/pacman.d/hooks 2>/dev/null
	bootctl --esp-path="$ESP_MOUNTPOINT" install

	echo -e "default archlinux*" | tee "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "timeout 5" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "console-mode max" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null
	echo -e "default @saved" | tee -a "${ESP_MOUNTPOINT}/loader/loader.conf" &>/dev/null

	cat <<EOF >"$ROOT_MOUNTPOINT/etc/pacman.d/hooks/95-systemd-boot.hook"
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

	_add_loaders

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
