setting_storage() {
	clear
	print_color "$MAGENTA" "Configuring fstab... \n"

	disks=("$(lsblk -p -l -n -f -o name)")
	esp_uuid=$(get_partinfo "uuid" "$EFI_PARTITION")
	esp_type=$(get_partinfo "type" "$EFI_PARTITION")

	root_uuid=$(get_partinfo "uuid" "$ROOT_PARTITION")
	root_type=$(get_partinfo "type" "$ROOT_PARTITION")

	echo -e "# <file system> <dir> <type> <options> <dump> <pass>" | tee "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
	echo -e "UUID=$esp_uuid     ${ESP_MOUNTPOINT#${ROOT_MOUNTPOINT}}       $esp_type      umask=0077      0       1" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
	echo -e "UUID=$root_uuid     /     $root_type        errors=remount-ro      0       1" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null

	for extra_disk_part in "${disks[@]}"; do
		local extra_type=$(get_partinfo "type" "$extra_disk_part")
		local extra_uuid=$(get_partinfo "uuid" "$extra_disk_part")
		local extra_label=$(get_partinfo "label" "$extra_disk_part")
		local extra_mountpoint="/media/$extra_label"
		if [[ -z $extra_label ]]; then
			extra_mountpoint="/media/$extra_uuid"
		fi

		if ! [[ -z $extra_type ]]; then
			case "$extra_type" in
			ntfs | exfat)
				echo -e "UUID=$extra_uuid $extra_mountpoint $extra_fstype defaults,uid=$uid,gid=$gid,nofail 0 0" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab
				;;
			ext4)
				echo -e "UUID=$extra_uuid $extra_mountpoint $extra_fstype defaults,nofail 0 0" | tee -a "$ROOT_MOUNTPOINT"/etc/fstab
				;;
			esac

		fi
	done

	if [[ $SWAP_METHOD == "1" ]]; then
		if [[ "$SWAP_PARTITION" == "/swapfile" ]]; then
			echo -e "/swapfile     none        swap        defaults        0       0" |
				tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
		else
			echo -e "UUID=$(get_partition "UUID" "$ROOT_PARTITION")     none        swap        defaults        0       0" |
				tee -a "$ROOT_MOUNTPOINT"/etc/fstab &>/dev/null
		fi
	fi
}
