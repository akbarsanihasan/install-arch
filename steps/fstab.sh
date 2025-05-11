gen_fstab() {
	clear
	info "Configuring fstab"

	mapfile -t disks < <(lsblk -p -l -n -f -o name)

	local esp_uuid=$(get_partinfo "uuid" "$EFI_PARTITION")
	local esp_type=$(get_partinfo "type" "$EFI_PARTITION")

	local root_uuid=$(get_partinfo "uuid" "$ROOT_PARTITION")
	local root_type=$(get_partinfo "type" "$ROOT_PARTITION")

	local uid=$(arch-chroot "$ROOT_MOUNTPOINT" id -u "$USERNAME")
	local gid=$(arch-chroot "$ROOT_MOUNTPOINT" id -g "$USERNAME")

	local MIN_SIZE_GB=8

	echo -e "# <file system> <dir> <type> <options> <dump> <pass>" | tee "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
	echo -e "UUID=$esp_uuid     ${ESP_MOUNTPOINT#${ROOT_MOUNTPOINT}}       $esp_type      umask=0077      0       1" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
	echo -e "UUID=$root_uuid     /     $root_type        errors=remount-ro      0       1" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null

	for disk in "${disks[@]}"; do
		local type=$(get_partinfo "type" "$disk")
		local uuid=$(get_partinfo "uuid" "$disk")
		local label=$(get_partinfo "label" "$disk")
		local mountpoint="/media/$label"
		if [[ -z $label ]]; then
			mountpoint="/media/$uuid"
		fi
		local size_bytes=$(df -BG --output=size "$disk" | tail -n 1 | tr -d 'G')
		local size_gb=$((size_bytes / 1024 / 1024 / 1024))

		if [[ $(lsblk -dno RM "$disk") -eq 1 ]]; then
			continue
		fi

		if [ "$size_gb" -lt "$MIN_SIZE_GB" ]; then
			continue
		fi

		if [[ -z $type ]]; then
			continue
		fi

		local options="defaults,nofail"
		if [[ $type == "ntfs" ]] || [[ $type == "exfat" ]]; then
			options+="uid=$uid,gid=$gid"
		fi

		echo -e "UUID=$uuid $mountpoint $fstype $options 0 0" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab
	done

	local swap_id="$SWAP_PARTITION"
	if ! [[ "$SWAP_PARTITION" == "/swapfile" ]]; then
		swap_id="UUID=$(get_partition "UUID" "$ROOT_PARTITION")"
	fi
	if [[ $SWAP_METHOD == "1" ]]; then
		echo -e "$swap_id     none        swap        defaults        0       0" |
			tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
	fi

}
