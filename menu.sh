export TIMEZONE=""

export HOST_NAME=""
export USERNAME=""
export ROOT_PASSWORD=""
export USER_PASSWORD=""

export EFI_PARTITION=""
export ROOT_PARTITION=""

export SWAP_METHOD=""
export SWAP_PARTITION=""
export HIBERNATION=""

export KERNEL=""
export BOOTLOADER="1"

export CONFIRM_INSTALL=""

timezone() {
	echo "Select your timezone: "
	TIMEZONE=$(tzselect -n 10)
	clear
}

hostname() {
	local default_hostname=$(hostnamectl | awk '/Hardware Model/{print $3}')
	info "Default hostname would be: $default_hostname"
	HOST_NAME=$(input "Enter your hostname")

	if [[ -z "$HOST_NAME" ]]; then
		HOST_NAME=$default_hostname
	fi

	clear
}

username() {
	USERNAME=$(input_noempty "Enter your username")
	clear
}

root_password() {
	info "Leave it empty to disable"
	ROOT_PASSWORD=$(input_silent "Enter your Root password")

	if [[ -n "$ROOT_PASSWORD" ]]; then
		echo -e
		ROOT_PASSWORD_VERIFY=$(input_silent "Verify your root password")

		if [[ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_VERIFY" ]]; then
			clear
			warn "Password doesn't match, try again"
			root_password
		fi
	fi

	clear
}

user_password() {
	info "User password cannot be empty"
	USER_PASSWORD=$(input_silent "Enter your User password")
	echo -e
	USER_PASSWORD_VERIFY=$(input_silent "Verify your User password")

	if [[ -z "$USER_PASSWORD" ]]; then
		clear
		warn "Cannot be empty"
		user_password
	fi

	if [[ "$USER_PASSWORD" != "$USER_PASSWORD_VERIFY" ]]; then
		clear
		warn "Password doesn't match,"
		user_password
	fi

	clear
}

efi_partition() {
	local partition=""
	local partition_type=""
	local confirm=""

	list_disk
	echo -e
	info "Type the full path, e.g., /dev/nvme0n1p1"
	info "Make sure this partition is safe to format"
	partition=$(input_noempty "Select your EFI partition")

	if ! blkid "$partition" &>/dev/null; then
		clear
		error "Cannot get partition. format or check the partition"
		echo -e
		efi_partition
		return 0
	fi

	partition_type=$(get_partinfo "type" "$partition")

	if [[ -n "$partition_type" ]]; then
		warn "${partition} is formatted as ${partition_type} and will be erased."
		confirm=$(input_noempty "Confirm? (y/n)")

		if ! [[ "$confirm" =~ [Yy] ]]; then
			clear
			efi_partition
			return 0
		fi
	fi

	EFI_PARTITION="$partition"

	clear
}

root_partition() {
	local partition=""
	local partition_type=""
	local confirm=""

	list_disk
	echo -e
	info "Type the full path e.g., /dev/nvme0n1p2"
	info "Make sure this partition is safe to format"
	partition=$(input_noempty "Select your ROOT partition")

	if ! blkid "$partition" &>/dev/null; then
		clear
		error "Cannot get partition. format or check the partition"
		echo -e
		root_partition
		return 0
	fi

	if [[ "$partition" == "$EFI_PARTITION" ]]; then
		clear
		error "Partition has been used for EFI"
		echo -e
		root_partition
		return 0
	fi

	partition_type=$(get_partinfo "type" "$partition")

	if [[ -n "$partition_type" ]]; then
		warn "${partition} is formatted as ${partition_type} and will be erased."
		confirm=$(input_noempty "Confirm? (y/n)")

		if ! [[ "$confirm" =~ [Yy] ]]; then
			clear
			root_partition
			return 0
		fi
	fi

	ROOT_PARTITION="$partition"

	clear
}

swap_method() {
	info "This option is optional"
	info "Zram only support GRUB as bootloader"
	SWAP_METHOD=$(option "Choose swap method" "Swap" "Zram")
	clear
}

swap_partition() {
	local partition

	list_disk
	echo -e
	info "Type the full path e.g., /dev/nvme0n1p4"
	info "To us swap file type '/swapfile' to the input"
	info "To cancel this option type 'n' to the input"
	partition=$(input "Select your SWAP partition")

	if [[ "$partition" == "n" ]]; then
		SWAP_METHOD=""
		return 0
	fi

	if [[ "$partition" == "$EFI_PARTITION" ]]; then
		clear
		error "Partition has been used for EFI"
		echo -e
		swap_partition
		return 0
	fi

	if [[ "$partition" == "$ROOT_PARTITION" ]]; then
		clear
		error "Partition has been used for ROOT"
		echo -e
		swap_partition
		return 0
	fi

	if includes_array "$partition" "${EXTRA_STORAGE[@]}"; then
		clear
		error "Partition has been used for extra storage"
		echo -e
		swap_partition
		return 0
	fi

	if ! blkid "$partition" &>/dev/null && ! [[ "$partition" == '/swapfile' ]]; then
		clear
		error "Cannot get partition. format or check the partition"
		echo -e
		swap_partition
		return 0
	fi

	if [[ ${partition} != "/swapfile" ]]; then
		local partition_type=""
		partition_type=$(get_partinfo "type" "$partition")

		if [[ -n "$partition_type" ]]; then
			warn "${partition} is formatted as ${partition_type} and will be erased."
			confirm=$(input_noempty "Confirm? (y/n)")

			if ! [[ "$confirm" =~ [Yy] ]]; then
				clear
				swap_partition
				return 0
			fi
		fi
	fi

	SWAP_PARTITION="$partition"

	clear
}

swap() {
	if [[ "$SWAP_METHOD" -eq "1" ]]; then
		swap_partition
	fi
}

kernel() {
	KERNEL=$(option_noempty "Select kernel" "Linux" "Linux-zen")
	clear

	if [[ -z "$KERNEL" ]]; then
		kernel
		clear
	fi
}

bootloader() {
	BOOTLOADER=$(option_noempty "Select the bootloader" "Grub" "Systemd-boot")
	clear
}

summary() {
	print_color "$MAGENTA" "Summary: "
	echo -e

	print_color "$GREEN" "Timezone: "
	print_color "$WHITE" "$TIMEZONE"
	echo -e

	print_color "$GREEN" "hostname: "
	print_color "$WHITE" "$HOST_NAME"
	echo -e

	print_color "$GREEN" "User: "
	print_color "$WHITE" "$USERNAME"
	echo -e

	print_color "$GREEN" "Root Password: "
	if [[ -n "$ROOT_PASSWORD" ]]; then
		print_color "$WHITE" "enabled"
	else
		print_color "$WHITE" "disabled"
	fi
	echo -e

	print_color "$GREEN" "User Password: "
	if [[ -n "$USER_PASSWORD" ]]; then
		print_color "$WHITE" "yes"
	else
		print_color "$WHITE" "no"
	fi
	echo -e

	print_color "$GREEN" "EFI Partition: "
	print_color "$WHITE" "$EFI_PARTITION"
	echo -e

	print_color "$GREEN" "ROOT Partition: "
	print_color "$WHITE" "$ROOT_PARTITION"
	echo -e

	print_color "$GREEN" "Swap Method: "
	if [[ "$SWAP_METHOD" -eq "1" ]]; then
		print_color "$WHITE" "Swap"
	fi
	if [[ "$SWAP_METHOD" -eq "2" ]]; then
		print_color "$WHITE" "Zram"
	fi
	echo -e

	if [[ "$SWAP_METHOD" -eq "1" ]]; then
		print_color "$GREEN" "Swap partition: "
		print_color "$WHITE" "$SWAP_PARTITION"
		echo -e
	fi

	print_color "$GREEN" "Kernel: "
	if [[ "$KERNEL" -eq "1" ]]; then
		print_color "$WHITE" "Linux"
	fi
	if [[ "$KERNEL" -eq "2" ]]; then
		print_color "$WHITE" "Linux zen"
	fi
	echo -e

	print_color "$GREEN" "Bootloader: "
	if [[ "$BOOTLOADER" -eq "1" ]]; then
		print_color "$WHITE" "GRUB"
	fi
	if [[ "$BOOTLOADER" -eq "2" ]]; then
		print_color "$WHITE" "Systemd-boot"
	fi
	echo -e

	CONFIRM_INSTALL=$(input_noempty "Confirm installation? (y/n)")
}
