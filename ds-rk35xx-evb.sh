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

if [ "$(id -u)" = "0" ]; then
	echo -e "${COLOR_RED}This must be executed without root privileges!${COLOR_RESET}" >&2
	exit 1
fi

dependencies=(cut git grep head make)
for cmd in "${dependencies[@]}"; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo -e "${COLOR_RED}Error: Required command '$cmd' not found${COLOR_RESET}" >&2
		exit 1
	fi
done

show_help() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  -h, --help           Show this help message"
	echo "  -b, --board NAME     Set board name and create board.cfg"
	echo ""
	echo "If -b option is provided, creates board.cfg with BOARD_NAME=value"

	exit 0
}

get_board_from_cfg() {
	local cfg_file="$1"
	if [[ -f "$cfg_file" ]]; then
		grep -E '^BOARD_NAME=' "$cfg_file" | head -1 | cut -d'=' -f2-
	fi
}

BOARD_NAME=""
while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			show_help
			;;
		-b|--board)
			if [[ -z "$2" || "$2" =~ ^- ]]; then
				echo -e "${COLOR_RED}Error: Board name is required for -b option${COLOR_RESET}" >&2
				exit 1
			fi
			BOARD_NAME="$2"
			shift 2
			;;
		*)
			echo -e "${COLOR_RED}Error: Unknown option: $1${COLOR_RESET}" >&2
			echo "Use -h for help"
			exit 1
			;;
	esac
done

script_path=$(readlink -f -- "$0")
ROOT=$(dirname -- "$script_path")

GIT=https://github.com/MacroGroup
BRANCH=macro
REPO=buildroot
DEFCONFIG=diasom_rk35xx_evb_defconfig
OUTPUT="$ROOT/output/ds-rk35xx-evb"
BOARD_CFG="$OUTPUT/board.cfg"

mkdir -p "$OUTPUT"

if [[ -n "$BOARD_NAME" ]]; then
	CURRENT_BOARD=$(get_board_from_cfg "$BOARD_CFG")

	if [[ -f "$BOARD_CFG" ]]; then
		if [[ "$CURRENT_BOARD" == "$BOARD_NAME" ]]; then
			echo -e "${COLOR_GREEN}Board name '$BOARD_NAME' matches existing configuration.${COLOR_RESET}"
		else
			echo -e "${COLOR_RED}Error: Board name mismatch!${COLOR_RESET}" >&2
			echo -e "${COLOR_RED}Existing board: $CURRENT_BOARD${COLOR_RESET}" >&2
			echo -e "${COLOR_RED}Requested board: $BOARD_NAME${COLOR_RESET}" >&2
			echo -e "${COLOR_YELLOW}Please remove $BOARD_CFG manually or use the correct board name${COLOR_RESET}" >&2
			exit 1
		fi
	else
		echo "BOARD_NAME=$BOARD_NAME" > "$BOARD_CFG"
		echo -e "${COLOR_GREEN}Board name set to: $BOARD_NAME${COLOR_RESET}"
		echo -e "${COLOR_GREEN}Configuration saved to: $BOARD_CFG${COLOR_RESET}"
	fi
elif [[ -f "$BOARD_CFG" ]]; then
	echo -e "${COLOR_RED}Error: board.cfg already exists at $BOARD_CFG${COLOR_RESET}" >&2
	CURRENT_BOARD=$(get_board_from_cfg "$BOARD_CFG")
	if [[ -n "$CURRENT_BOARD" ]]; then
		echo -e "${COLOR_YELLOW}Current board name: $CURRENT_BOARD${COLOR_RESET}" >&2
	fi
	echo -e "${COLOR_YELLOW}Please remove it manually or use -b option to specify a board name${COLOR_RESET}" >&2
	exit 1
else
	echo -e "${COLOR_YELLOW}No board.cfg found, using default configuration.${COLOR_RESET}"
fi

cd "$ROOT" || exit 1

if [ -d ".git" ]; then
	echo -e "${COLOR_CYAN}Checking repository status...${COLOR_RESET}"

	if ! git fetch; then
		echo -e "${COLOR_RED}Error: Failed to fetch from remote repository${COLOR_RESET}" >&2
		exit 1
	fi

	UPSTREAM=$(git rev-parse --abbrev-ref "@{u}" 2>/dev/null)

	if [ -z "$UPSTREAM" ]; then
		echo -e "${COLOR_YELLOW}Warning: No upstream branch configured for the current repository${COLOR_RESET}"
	else
		LOCAL=$(git rev-parse @)
		REMOTE=$(git rev-parse "$UPSTREAM")
		BASE=$(git merge-base @ "$UPSTREAM")

		if [ "$LOCAL" != "$REMOTE" ]; then
			if [ "$LOCAL" = "$BASE" ]; then
				echo -e "${COLOR_RED}The local branch lags behind the remote one!${COLOR_RESET}"
				echo -e "${COLOR_YELLOW}Do a 'git pull' first, then re-run $0.${COLOR_RESET}"
			elif [ "$REMOTE" = "$BASE" ]; then
				echo -e "${COLOR_YELLOW}Local branch overtakes remote! Probably needs a push.${COLOR_RESET}"
			else
				echo -e "${COLOR_RED}Local and remote branches are diverged!${COLOR_RESET}"
			fi
			exit 1
		else
			echo -e "${COLOR_GREEN}Repository is up-to-date with upstream.${COLOR_RESET}"
		fi
	fi
else
	echo -e "${COLOR_YELLOW}Warning: Current directory is not a git repository, skipping repository checks${COLOR_RESET}"
fi

echo -e "${COLOR_CYAN}Processing $REPO repository...${COLOR_RESET}"
if [ -d "$ROOT/buildroot/.git" ]; then
	echo -e "${COLOR_BLUE}Updating $REPO repository...${COLOR_RESET}"
	git -C "$ROOT/$REPO" pull --rebase origin $BRANCH || exit 1
	echo -e "${COLOR_GREEN}Repository $REPO updated successfully.${COLOR_RESET}"
else
	echo -e "${COLOR_BLUE}Cloning $REPO repository...${COLOR_RESET}"
	git clone -b $BRANCH $GIT/$REPO.git "$ROOT/$REPO" || exit 1
	echo -e "${COLOR_GREEN}Repository $REPO cloned successfully.${COLOR_RESET}"
fi

echo -e "${COLOR_CYAN}Starting build process...${COLOR_RESET}"
cd "$ROOT/$REPO" || exit 1

echo -e "${COLOR_BLUE}Configuring build...${COLOR_RESET}"
make defconfig BR2_DEFCONFIG=configs/$DEFCONFIG O="$OUTPUT" || exit 1
echo -e "${COLOR_GREEN}Configuration completed successfully.${COLOR_RESET}"

echo -e "${COLOR_BLUE}Building project...${COLOR_RESET}"
cd "$OUTPUT" || exit 1

if make; then
	echo -e "${COLOR_GREEN}Build completed successfully!${COLOR_RESET}"
else
	echo -e "${COLOR_RED}Build failed!${COLOR_RESET}" >&2
	exit 1
fi
