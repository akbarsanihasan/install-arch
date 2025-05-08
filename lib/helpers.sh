list_disk() {
	lsblk -o name,start,size,type,fstype
}

get_partinfo() {
	local info
	info=$(echo "$1" | tr "[:lower:]" "[:upper:]")

	blkid -s "$info" -o value "$2"
}

includes_array() {
	local str=$1

	shift

	for item in "${@}"; do
		if [[ "$str" == "$item" ]]; then
			return 0
		fi
	done

	return 1
}

check_swap() {
	if [[ -f /proc/swaps ]] && [[ "$(wc -l </proc/swaps)" -gt 1 ]]; then
		return 0
	fi

	return 1
}
