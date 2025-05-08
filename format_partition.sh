delete_efi_entry() {
	label="$1"
	entry_numbers=()

	while IFS= read -r entry_number; do
		entry_number="${entry_number/\*/}"
		entry_number="${entry_number#Boot}"
		entry_numbers+=("$entry_number")
	done < <(efibootmgr | grep -i "$label" | awk '{print $1}')

	if [ ${#entry_numbers[@]} -gt 0 ]; then
		for entry_number in "${entry_numbers[@]}"; do
			efibootmgr -b "$entry_number" -B
		done

		echo "EFI boot entry(s) with label '$label' deleted successfully"
	fi
}

checkmount() {
	if [[ "$(findmnt -n -o TARGET "${1}")" == "${2}" ]]; then
		return 0
	fi

	return 1
}

format_partition() {
	clear
	print_color "$MAGENTA" "Formatting selected partition...\n"

	if check_swap; then
		if ! checkmount "$ROOT_PARTITION" "$ROOT_MOUNTPOINT"; then
			mount "$ROOT_PARTITION" "$ROOT_MOUNTPOINT"
		fi
		arch-chroot "$ROOT_MOUNTPOINT" swapoff -a || true
	fi

	if checkmount "$ROOT_PARTITION" "$ROOT_MOUNTPOINT"; then
		umount -Rlq "$ROOT_MOUNTPOINT"
	fi

	if checkmount "$EFI_PARTITION" "$ESP_MOUNTPOINT"; then
		umount -Rlq "$ESP_MOUNTPOINT"
	fi

	if checkmount "$EFI_PARTITION" "${ROOT_MOUNTPOINT}/boot/efi"; then
		umount -Rlq "${ROOT_MOUNTPOINT}/boot/efi"
	fi

	if ! [[ $(get_partinfo "type" "$EFI_PARTITION") =~ ^(vfat|fat)$ ]]; then
		mkfs.fat -F32 -n EFI "$EFI_PARTITION"
	fi
	mkfs.ext4 -F -L Archlinux "$ROOT_PARTITION"

	mount "$ROOT_PARTITION" "$ROOT_MOUNTPOINT"
	mount "$EFI_PARTITION" "$ESP_MOUNTPOINT" --mkdir

	rm -rf "$ESP_MOUNTPOINT"/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &>/dev/null
	rm -rf "$ROOT_MOUNTPOINT"/boot/efi/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &>/dev/null
	rm -rf "{$ROOT_MOUNTPOINT}"/boot/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &>/dev/null

	success "Partitioning disk"
	sleep 3
}
