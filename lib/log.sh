export BLACK=30
export RED=31
export GREEN=32
export YELLOW=33
export BLUE=34
export MAGENTA=35
export CYAN=36
export WHITE=37

print_color() {
	local color_code=$1
	local text=$2
	echo -en "\e[${color_code}m${text}\e[0m"
}

success() {
	local text=$1
	print_color "$GREEN" "Success: "
	print_color "$WHITE" "${text}\n"
}

info() {
	local text=$1
	print_color "$BLUE" "Info: "
	print_color "$WHITE" "${text}\n"
}

warn() {
	local text=$1
	print_color "$YELLOW" "Warning: "
	print_color "$WHITE" "${text}\n"
}

error() {
	local text=$1
	print_color "$RED" "Error: "
	print_color "$WHITE" "${text}\n"
}
