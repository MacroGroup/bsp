#!/bin/bash

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

dependencies=(git make)
for cmd in "${dependencies[@]}"; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo -e "${COLOR_RED}Error: Required command '$cmd' not found${COLOR_RESET}" >&2
		exit 1
	fi
done

script_path=$(readlink -f -- "$0")
ROOT=$(dirname -- "$script_path")

GIT=https://github.com/MacroGroup
BRANCH=macro
REPO=buildroot
DEFCONFIG=diasom_imx8m_evb_defconfig
OUTPUT="$ROOT/output/ds-imx8m-evb"

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

export CMAKE_POLICY_VERSION_MINIMUM=3.5
if make; then
	echo -e "${COLOR_GREEN}Build completed successfully!${COLOR_RESET}"
else
	echo -e "${COLOR_RED}Build failed!${COLOR_RESET}" >&2
	exit 1
fi
