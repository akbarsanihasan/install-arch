input() {
  local input
  local message=$1

  read -rp "$message: " input

  echo "$input"
}

input_silent() {
  local input
  local message=$1

  read -rsp "$message: " input

  echo "$input"
}

input_noempty() {
  local input
  local message=$1

  read -rp "$message: " input

  if [[ -z "$input" ]]; then
    echo -e >&2
    warn "Input cannot be empty"
    input_noempty "$message"
    return 0
  fi

  echo "$input"
}

input_noempty_silent() {
  local input
  local message=$1

  read -rsp "$message: " input

  if [[ -z "$input" ]]; then
    echo -e >&2
    warn "Input cannot be empty"
    input_noempty_silent "$message"
    return 0
  fi

  echo "$input"
}

option() {
  local selection
  local message=$1

  shift 1
  local options=("${@}")

  for opt_index in "${!options[@]}"; do
    echo "$((opt_index + 1))) ${options[$opt_index]}" >&2
  done

  read -rp "${message}: " selection

  if [[ -z "$selection" ]]; then
    echo ""
    return 0
  fi

  if ! [[ $selection =~ ^[0-9]+$ ]]; then
    clear >&2
    error "Invalid selection, Not a number" >&2
    option "$message" "${options[@]}"
    return 0
  fi

  if [[ $selection -lt 1 || $selection -gt ${#options[@]} ]]; then
    clear >&2
    error "Invalid selection" >&2
    option "$message" "${options[@]}"
    return 0
  fi

  echo "$selection"
}

option_noempty() {
  local selection
  local message=$1

  shift 1
  local options=("${@}")

  for opt_index in "${!options[@]}"; do
    echo "$((opt_index + 1))) ${options[$opt_index]}" >&2
  done

  selection=$(input_noempty "$message")

  if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
    clear >&2
    error "Invalid selection, Not a number" >&2
    option_noempty "$message" "${options[@]}"
    return 0
  fi

  if [[ "$selection" -lt 1 || "$selection" -gt ${#options[@]} ]]; then
    clear >&2
    error "Invalid selection" >&2
    option_noempty "$message" "${options[@]}"
    return 0
  fi

  echo "$selection"
}
