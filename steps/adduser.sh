adduser() {
    clear
    info "Adding user...\n"

    useradd -mG wheel -R "$ROOT_MOUNTPOINT" "$USERNAME"

    arch-chroot "$ROOT_MOUNTPOINT" sh -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\" | passwd $USERNAME" &>/dev/null
    if [[ -n "$ROOT_PASSWORD" ]]; then
        arch-chroot "$ROOT_MOUNTPOINT" sh -c "echo -e \"$ROOT_PASSWORD\n$ROOT_PASSWORD\" | passwd root" &>/dev/null
    fi

    sed -E -i 's/^# (%wheel ALL=\(ALL:ALL\) ALL)/\1/' "$ROOT_MOUNTPOINT"/etc/sudoers

    success "Successfully adding user\n"
    sleep 3
}
