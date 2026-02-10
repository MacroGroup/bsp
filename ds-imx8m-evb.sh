#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0+
# SPDX-FileCopyrightText: Alexander Shiyan <shc_work@mail.ru>

if [ -t 1 ]; then
	COLOR_RED='\033[0;31m'
	COLOR_YELLOW='\033[0;33m'
	COLOR_GREEN='\033[0;32m'
	COLOR_CYAN='\033[0;36m'
	COLOR_BLUE='\033[0;34m'
	COLOR_RESET='\033[0m'
else
	COLOR_RED=""
	COLOR_YELLOW=""
	COLOR_GREEN=""
	COLOR_CYAN=""
	COLOR_BLUE=""
	COLOR_RESET=""
fi

SCRIPT_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$SCRIPT_PATH")

REQUIRED_CMDS=(cut git grep head make)

GIT_REPO="https://github.com/MacroGroup/buildroot"
DEFAULT_BRANCH="macro"
DEFCONFIG="diasom_imx8m_evb_defconfig"
OUTPUT_DIR="$SCRIPT_DIR/output/ds-imx8m-evb"
BOARD_CFG="$OUTPUT_DIR/board.cfg"

print_error() { echo -e "${COLOR_RED}Error: $1${COLOR_RESET}" >&2; }
print_warning() { echo -e "${COLOR_YELLOW}$1${COLOR_RESET}"; }
print_success() { echo -e "${COLOR_GREEN}$1${COLOR_RESET}"; }
print_info() { echo -e "${COLOR_CYAN}$1${COLOR_RESET}"; }

check_dependencies() {
	local missing=()
	for cmd in "${REQUIRED_CMDS[@]}"; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			missing+=("$cmd")
		fi
	done

	if [ ${#missing[@]} -gt 0 ]; then
		print_error "Missing required commands: ${missing[*]}"
		exit 1
	fi

	if [ "$(id -u)" = "0" ]; then
		print_error "This must be executed without root privileges!"
		exit 1
	fi
}

get_config_value() {
	local cfg_file="$1"
	local key="$2"
	if [[ -f "$cfg_file" ]]; then
		grep -E "^${key}=" "$cfg_file" | head -1 | cut -d'=' -f2-
	fi
}

validate_config() {
	local board_name="$1"
	local branch_name="$2"
	local config_board=""
	local config_branch=""

	if [[ -f "$BOARD_CFG" ]]; then
		config_board=$(get_config_value "$BOARD_CFG" "BOARD_NAME")
		config_branch=$(get_config_value "$BOARD_CFG" "BRANCH")

		if [[ -n "$config_board" && -n "$board_name" && "$board_name" != "$config_board" ]]; then
			print_error "Board name mismatch!"
			print_error "Config: $config_board, Command line: $board_name"
			print_warning "Remove $BOARD_CFG manually or use correct board name"
			return 1
		fi

		if [[ -n "$config_branch" && -n "$branch_name" && "$branch_name" != "$config_branch" ]]; then
			print_error "Branch mismatch!"
			print_error "Config: $config_branch, Command line: $branch_name"
			print_warning "Remove $BOARD_CFG manually or use correct branch"
			return 1
		fi

		board_name="${board_name:-$config_board}"
		branch_name="${branch_name:-$config_branch:-$DEFAULT_BRANCH}"

		print_success "Using configuration: board=${board_name:-none}, branch=$branch_name"
		return 0
	fi

	if [[ -n "$board_name" ]]; then
		branch_name="${branch_name:-$DEFAULT_BRANCH}"
		{
			echo "BOARD_NAME=$board_name"
			echo "BRANCH=$branch_name"
		} > "$BOARD_CFG"

		print_success "Configuration created: board=$board_name, branch=$branch_name"
		return 0
	else
		branch_name="${branch_name:-$DEFAULT_BRANCH}"
		print_warning "No board configuration, using default settings"
		print_warning "Branch: $branch_name"
		return 0
	fi
}

get_build_branch() {
	local board_name="$1"
	local branch_name="$2"
	local config_branch=""

	if [[ -f "$BOARD_CFG" ]]; then
		config_branch=$(get_config_value "$BOARD_CFG" "BRANCH")
	fi

	if [[ -n "$branch_name" ]]; then
		echo "$branch_name"
	elif [[ -n "$config_branch" ]]; then
		echo "$config_branch"
	else
		echo "$DEFAULT_BRANCH"
	fi
}

check_git_status() {
	if [ -d ".git" ]; then
		print_info "Checking repository status..."

		if ! git fetch; then
			print_error "Failed to fetch from remote repository"
			exit 1
		fi

		local upstream=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)

		if [ -z "$upstream" ]; then
			print_warning "No upstream branch configured"
			return
		fi

		local local_commit=$(git rev-parse @)
		local remote_commit=$(git rev-parse "$upstream")
		local base_commit=$(git merge-base @ "$upstream")

		if [ "$local_commit" != "$remote_commit" ]; then
			if [ "$local_commit" = "$base_commit" ]; then
				print_error "Local branch is behind remote"
				print_warning "Run 'git pull' and retry"
			elif [ "$remote_commit" = "$base_commit" ]; then
				print_warning "Local branch is ahead of remote"
			else
				print_error "Branches have diverged"
			fi
			exit 1
		fi

		print_success "Repository is up-to-date"
	else
		print_warning "Not a git repository, skipping status check"
	fi
}

setup_buildroot() {
	local branch="$1"

	print_info "Using branch: $branch"

	if [ -d "buildroot/.git" ]; then
		local current_branch=$(git -C "buildroot" rev-parse --abbrev-ref HEAD 2>/dev/null)

		if [[ "$current_branch" != "$branch" ]]; then
			print_warning "Buildroot is on branch '$current_branch', switching to '$branch'"
			git -C "buildroot" checkout "$branch" || {
				print_error "Failed to switch to branch '$branch'"
				exit 1
			}
		fi

		print_info "Updating buildroot repository..."
		git -C "buildroot" pull --rebase origin "$branch" || exit 1
		print_success "Buildroot repository updated"
	else
		print_info "Cloning buildroot repository..."
		git clone -b "$branch" "$GIT_REPO" "buildroot" || exit 1
		print_success "Buildroot repository cloned"
	fi
}

run_build() {
	print_info "Starting build process..."

	cd "buildroot" || exit 1
	print_info "Configuring build..."

	make defconfig BR2_DEFCONFIG="configs/$DEFCONFIG" O="$OUTPUT_DIR" || exit 1
	print_success "Configuration completed"

	cd "$OUTPUT_DIR" || exit 1
	print_info "Building project..."

	if make; then
		print_success "Build completed successfully!"
	else
		print_error "Build failed!"
		exit 1
	fi
}

show_help() {
	cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help           Show this help message
  -b, --board NAME     Set board name
  -r, --branch NAME    Set buildroot branch (default: "$DEFAULT_BRANCH")

Behavior:
  1. If board.cfg doesn't exist:
     - With -b: creates board.cfg with board name and branch
     - Without -b: uses default settings (no config created)
     - Branch priority: command line (-r) > default

  2. If board.cfg exists:
     - All specified parameters must match existing values
     - Unspecified parameters are taken from config
     - To change any value: remove board.cfg manually

Examples:
  $0                         # Use default settings (no config)
  $0 -b my_board             # Create config: board=my_board, branch=macro
  $0 -b my_board -r custom   # Create config: board=my_board, branch=custom
  $0 -r custom-branch        # Use specific branch, no config
  $0 -b existing_board       # Use existing config (branch from config)
  $0 -r existing_branch      # Use existing config (board from config)
EOF
	exit 0
}

main() {
	local board_name=""
	local branch_name=""

	while [[ $# -gt 0 ]]; do
		case $1 in
		-h|--help)
			show_help
			;;
		-b|--board)
			if [[ -z "$2" || "$2" =~ ^- ]]; then
				print_error "Board name is required for -b option"
				exit 1
			fi
			board_name="$2"
			shift 2
			;;
		-r|--branch)
			if [[ -z "$2" || "$2" =~ ^- ]]; then
				print_error "Branch name is required for -r option"
				exit 1
			fi
			branch_name="$2"
			shift 2
			;;
		*)
			print_error "Unknown option: $1"
			echo "Use -h for help"
			exit 1
			;;
		esac
	done

	check_dependencies
	mkdir -p "$OUTPUT_DIR"

	if ! validate_config "$board_name" "$branch_name"; then
		exit 1
	fi

	local build_branch=$(get_build_branch "$board_name" "$branch_name")

	cd "$SCRIPT_DIR" || exit 1
	check_git_status

	setup_buildroot "$build_branch"

	run_build
}

main "$@"
