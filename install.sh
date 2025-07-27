#!/usr/bin/env bash

clear
set -euo pipefail

source "./lib/helpers.sh"
source "./lib/prompt.sh"
source "./lib/log.sh"

if [[ "$(id -u)" -ne 0 ]]; then
  error "Script must run with root"
  exit 1
fi

if ! [[ -d /sys/firmware/efi ]]; then
  error "This script only support for EFI firmware"
  exit 1
fi

input_password() {
  local password=$(input_noempty_silent "Input password")
  echo -e >&2
  local password_verify=$(input_noempty_silent "Verify password")

  if [[ $password != $password_verify ]]; then
    clear >&2
    error "Password were not match"
    input_password
    return 0
  fi

  echo $password
}

selected_partition=()
select_partition() {
  local partition=""
  local partition_type=""
  local confirm=""

  list_disk
  echo -e >&2
  info "Type the full path e.g., /dev/nvme0n1p1"
  info "Make sure this partition is safe to format"
  partition=$(input_noempty "Select your $1 partition partition")

  if ! blkid "$partition" &> /dev/null; then
    clear >&2
    error "Cannot get partition. format or check the disk"
    select_partition $1
    return 0
  fi

  partition_type=$(get_partinfo "type" "$partition")
  if [[ -n "$partition_type" ]]; then
    warn "${partition} is formatted as ${partition_type} and will be erased."
    confirm=$(input_noempty "Confirm? (y/n)")
    if ! [[ "$confirm" =~ [Yy] ]]; then
      clear >&2
      select_partition $1
      return 0
    fi
  fi

  if array_includes "$partition" "${selected_partition[@]}"; then
    selected_partition=()
    clear >&2
    warn "${partition} is formatted as has selected"
    select_partition $1
    return 0
  fi

  echo "$partition"
}

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

CPU_VENDORS=("genuineintel" "authenticamd")
CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}' | tr "[:upper:]" "[:lower:]")
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

if ! array_includes $CPU_VENDOR ${CPU_VENDORS[@]}; then
  error "The $CPU_VENDOR cpu vendor is not supported"
  exit 1
fi

ROOT_MOUNTPOINT="/mnt"
ESP_MOUNTPOINT="$ROOT_MOUNTPOINT/boot"

DEFAULT_TIMEZONE="Asia/Jakarta"
: "${timezone:=$DEFAULT_TIMEZONE}"

DEFAULT_HOST=$(cat < /sys/class/dmi/id/product_version | cut -d ' ' -f 1 | tr -d "[:punct:][:space:]" | tr "[:upper:]" "[:lower:]")
: "${hostname:=${DEFAULT_HOST^}}"

DEFAULT_USERNAME="akbarsanihasan"
: "${username:=$DEFAULT_USERNAME}"

DEFAULT_KERNEL="linux"
: "${kernel:=$DEFAULT_KERNEL}"

info "Password for $username"
DEFAULT_USER_PASSWORD=$(input_password)
: "${user_password:=$DEFAULT_USER_PASSWORD}"

clear
esp=$(select_partition "ESP")
selected_partition+=($esp)

clear
root_partition=$(select_partition "ROOT")
selected_partition+=($root_partition)

bootloader=grub
swap_partition="/swapfile"

summary() {
  clear >&2
  print_color "$MAGENTA" "Summary: "
  echo -e >&2

  print_color "$GREEN" "Timezone: "
  print_color "$WHITE" "$timezone"
  echo -e >&2

  print_color "$GREEN" "hostname: "
  print_color "$WHITE" "$hostname"
  echo -e >&2

  print_color "$GREEN" "User: "
  print_color "$WHITE" "$username"
  echo -e >&2

  print_color "$GREEN" "User Password: "
  if [[ -n "$user_password" ]]; then
    print_color "$WHITE" "yes"
  else
    print_color "$WHITE" "no"
  fi
  echo -e >&2

  print_color "$GREEN" "EFI Partition: "
  print_color "$WHITE" "$esp"
  echo -e >&2

  print_color "$GREEN" "ROOT Partition: "
  print_color "$WHITE" "$root_partition"
  echo -e >&2

  print_color "$GREEN" "Swap Method: "
  print_color "$WHITE" "Swap"
  echo -e >&2

  print_color "$GREEN" "Swap partition: "
  print_color "$WHITE" "$swap_partition"
  echo -e >&2

  print_color "$GREEN" "Kernel: "
  print_color "$WHITE" "$kernel"
  echo -e >&2

  print_color "$GREEN" "Bootloader: "
  print_color "$WHITE" "$bootloader"

  echo -e >&2
  local summary=$(input_noempty "Confirm installation? (y/n)")

  echo $summary
}
confirm_install=$(summary)
if ! [[ "$confirm_install" =~ [Yy] ]]; then
    clear
    print_color "$GREEN" "Good bye.\n"
    exit 1
fi

echo -e
info "Configuring pacman and reflector"

timedatectl set-ntp true

pacman-key --init
pacman-key --populate
pacman -Sy --noconfirm reflector

if [[ ! -e /etc/pacman.d/mirrorlist.bak ]]; then
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
fi

reflector --verbose \
  --age 48 \
  --latest 20 \
  --fastest 5 \
  --country ID \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

if [[ ! -e /etc/pacman.conf.bak ]]; then
  cp /etc/pacman.conf /etc/pacman.conf.bak
fi

sed -i '/^#ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]\+/s/^#//' /etc/pacman.conf
sed -i '/^#Color/s/^#//' /etc/pacman.conf
sed -i '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

pacman-key --init && pacman-key --populate
pacman -Sy
success "Configuring pacman and reflector"
sleep 3

clear
info "Formatting partition"

if check_swap; then
  if ! checkmount "$root_partition" "$ROOT_MOUNTPOINT"; then
    mount "$root_partition" "$ROOT_MOUNTPOINT"
  fi
  arch-chroot "$ROOT_MOUNTPOINT" swapoff -a || true
fi

if checkmount "$root_partition" "$ROOT_MOUNTPOINT"; then
  umount -Rlq "$ROOT_MOUNTPOINT"
fi

if checkmount "$esp" "$ESP_MOUNTPOINT"; then
  umount -Rlq "$ESP_MOUNTPOINT"
fi

if checkmount "$esp" "${ROOT_MOUNTPOINT}/boot/efi"; then
  umount -Rlq "${ROOT_MOUNTPOINT}/boot/efi"
fi

if ! [[ $(get_partinfo "type" "$esp") =~ ^(vfat|fat)$ ]]; then
  mkfs.fat -F32 -n EFI "$esp"
fi
mkfs.ext4 -F -L Archlinux "$root_partition"

mount "$root_partition" "$ROOT_MOUNTPOINT"
mount "$esp" "$ESP_MOUNTPOINT" --mkdir

rm -rf "$ESP_MOUNTPOINT"/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &> /dev/null
rm -rf "$ROOT_MOUNTPOINT"/boot/efi/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &> /dev/null
rm -rf "{$ROOT_MOUNTPOINT}"/boot/{EFI/systemd,EFI/Archlinux,*.img,loader,vmlinuz-*,grub} &> /dev/null

success "Formatting partition"
sleep 3

clear
info "Installing base systems"
sleep 3

pacstrap "$ROOT_MOUNTPOINT" base "$kernel" linux-firmware vim

success "Installing base systems"
sleep 3

clear
info "Configuring locale"

additional_locale="id_ID.UTF-8"

ln -sf /usr/share/zoneinfo/"$timezone" "$ROOT_MOUNTPOINT"/etc/localtime
timedatectl set-ntp true &> /dev/null
hwclock --systohc &> /dev/null

arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_GB.UTF-8/s/^#//' /etc/locale.gen
arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#en_US.UTF-8/s/^#//' /etc/locale.gen
arch-chroot "$ROOT_MOUNTPOINT" sed -i "/^#$additional_locale/s/^#//" /etc/locale.gen

tee "$ROOT_MOUNTPOINT"/etc/locale.conf <<- EOF
LANG="en_GB.UTF-8"
LANGUAGE="en_GB.UTF-8"
LC_CTYPE="$additional_locale"
LC_COLLATE="$additional_locale"
LC_MESSAGES="$additional_locale"
LC_NAME="$additional_locale"
LC_NUMERIC="$additional_locale"
LC_TIME="$additional_locale"
LC_MONETARY="$additional_locale"
LC_PAPER="$additional_locale"
LC_ADDRESS="$additional_locale"
LC_TELEPHONE="$additional_locale"
LC_MEASUREMENT="$additional_locale"
LC_IDENTIFICATION="$additional_locale"
EOF

arch-chroot "$ROOT_MOUNTPOINT" locale-gen

success "Configuring locale"
sleep 3

clear
info "Configuring network"

pacstrap "$ROOT_MOUNTPOINT" networkmanager wpa_supplicant wireless_tools

echo "$hostname" | tee "$ROOT_MOUNTPOINT"/etc/hostname &> /dev/null

tee "$ROOT_MOUNTPOINT"/etc/hosts <<- EOF
127.0.0.1 localhost 
::1 localhost  
127.0.0.1 $hostname 
EOF

arch-chroot "$ROOT_MOUNTPOINT" systemctl enable NetworkManager

success "Configuring network"
sleep 3

clear
info "Adding user"

pacstrap "$ROOT_MOUNTPOINT" sudo

useradd -mG wheel -R "$ROOT_MOUNTPOINT" "$username"
arch-chroot "$ROOT_MOUNTPOINT" sh -c "echo $username:$user_password | chpasswd"
sed -E -i 's/^# (%wheel ALL=\(ALL:ALL\) ALL)/\1/' "$ROOT_MOUNTPOINT"/etc/sudoers

success "Adding user"
sleep 3

clear
info "Configuring pacman"

pacstrap "$ROOT_MOUNTPOINT" reflector pacman-contrib
arch-chroot "$ROOT_MOUNTPOINT" cp /etc/pacman.conf /etc/pacman.conf.bak
arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#ParallelDownloads[[:space:]]*=[[:space:]]*[0-9]\+/s/^#//' /etc/pacman.conf
arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#Color/s/^#//' /etc/pacman.conf
arch-chroot "$ROOT_MOUNTPOINT" sed -i '/^#[[:space:]]*\[multilib\]/,/^#[[:space:]]*Include = \/etc\/pacman.d\/mirrorlist/s/^#//' /etc/pacman.conf

success "Configuring pacman"
sleep 3

clear
info "Configuring Swap"

if check_swap; then
  warn "Swap file or partition already exists"
  exit 0
fi

swap_size_default=4096
swap_size_half=$((TOTAL_RAM / 2))
swap_size=$swap_size_default

if [[ $swap_size_half -lt $swap_size_default ]]; then
  swap_size=$swap_size_half
fi

arch-chroot "$ROOT_MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" status=progress
arch-chroot "$ROOT_MOUNTPOINT" chmod 600 "$swap_partition"

arch-chroot "$ROOT_MOUNTPOINT" mkswap "$swap_partition" -f
arch-chroot "$ROOT_MOUNTPOINT" swapon "$swap_partition"

success "Configuring swap"
sleep 3

clear
info "Installing bootloader"

pacstrap "$ROOT_MOUNTPOINT" grub os-prober efibootmgr dosfstools mtools
if [[ "$CPU_VENDOR" == "genuineintel" ]]; then
  pacstrap "$ROOT_MOUNTPOINT" intel-ucode
fi
if [[ "$CPU_VENDOR" == "authenticamd" ]]; then
  pacstrap "$ROOT_MOUNTPOINT" amd-ucode
fi

grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNTPOINT" --boot-directory="$ESP_MOUNTPOINT" --bootloader-id=Archlinux

tee "$ROOT_MOUNTPOINT"/etc/default/grub <<- EOF
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_CMDLINE_LINUX=""
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_GFXMODE=auto
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TIMEOUT_STYLE=hidden
GRUB_TERMINAL_INPUT=console
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=false
EOF

arch-chroot "$ROOT_MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg

success "Installing bootloader"
sleep 3

genfstab -U $ROOT_MOUNTPOINT

clear
success "Installing arch"
