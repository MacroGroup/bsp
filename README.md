# Boot Image Build System for MacroGroup Modules

This repository contains scripts for creating boot images used with debug boards based on [MacroGroup](https://macrogroup.ru/) [DiaSom modules](https://diasom.ru/).

## Build System Components
*(Component versions may vary per board)*
- **[barebox](https://barebox.org/) 2026.06+** (bootloader)
- **[buildroot](https://buildroot.org/) 2026.05+** (root filesystem generator)
- **[linux](https://kernel.org/) 6.19+** (Linux kernel)

---

## Building Images

### For DS-IMX8M-EVB:
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
./ds-imx8m-evb.sh
```
SD-card image created after successful build in the output/ds-imx8m-evb/images directory.

### For DS-RK3568-EVB or DS-RK3588-BTB-EVB:
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
```
First build - specify your board type:
```bash
# For DS-RK3568-EVB board:
./ds-rk35xx-evb.sh -b ds-rk3568-evb

# For DS-RK3588-BTB-EVB board:
./ds-rk35xx-evb.sh -b ds-rk3588-btb-evb
```
Subsequent builds (with existing configuration):
```bash
./ds-rk35xx-evb.sh -b ds-rk3568-evb  # Use the same board name as before
```
SD-card image created after successful build in the output/ds-rk35xx-evb/images directory.

## Board Configuration
The build system uses a board.cfg file to track board-specific configurations and can contain:
- **BOARD_NAME** - Your board name (required for persistent configuration)
- **BRANCH** - Buildroot branch name (optional, defaults to "macro")

## Configuration Rules
**1. No board.cfg exists:**
- **With** -b **option**: Creates board.cfg with specified board name and branch
```bash
# Creates config: BOARD_NAME=my_board, BRANCH=macro (default)
./ds-rk35xx-evb.sh -b my_board

# Creates config: BOARD_NAME=my_board, BRANCH=custom
./ds-rk35xx-evb.sh -b my_board -r custom
```

- **Without** -b **option**: Uses default settings (no config created)
```bash
# Uses default branch "macro", no board configuration
./ds-rk35xx-evb.sh

# Uses custom branch, no board configuration
./ds-rk35xx-evb.sh -r custom-branch
```

**2. board.cfg exists:**
- **All specified parameters must match existing values in the config**
- **Unspecified parameters are taken from the config**
- **To change any value: Remove board.cfg manually and start fresh**
- **Partial configs allowed: Can contain only BOARD_NAME, only BRANCH, or both**

**Examples with existing config (BOARD_NAME=my_board, BRANCH=master):**
```bash
# All match - OK
./ds-rk35xx-evb.sh -b my_board -r master

# Board matches, branch from config - OK
./ds-rk35xx-evb.sh -b my_board

# Branch matches, board from config - OK
./ds-rk35xx-evb.sh -r master

# Mismatch - ERROR
./ds-rk35xx-evb.sh -b different_board  # Error: board name mismatch
./ds-rk35xx-evb.sh -r different_branch # Error: branch mismatch
```

**Available options:**
- -h, --help - Show help message
- -b, --board NAME - Set board\
- -r, --branch NAME - Set buildroot branch (default: "macro")
- -o, --offline - Run in offline mode (skip network operations)

## Common Scenarios
**Starting fresh (no existing config):**
```bash
# Create config with board name and default branch
./ds-rk35xx-evb.sh -b ds-rk3568-evb

# Create config with board name and specific branch
./ds-rk35xx-evb.sh -b ds-rk3588-btb-evb -r master

# Build without saving config (uses default branch)
./ds-rk35xx-evb.sh
```
**Using existing configuration:**
```bash
# Check what's in your config
cat output/ds-rk35xx-evb/board.cfg

# Build with existing config (specify matching parameters)
./ds-rk35xx-evb.sh -b [board_from_config] -r [branch_from_config]
```
**Changing configuration:**
```bash
# Remove existing config
rm output/ds-rk35xx-evb/board.cfg

# Create new config
./ds-rk35xx-evb.sh -b new-board -r new-branch
```

## Offline Build Mode

When you have no internet access or want to avoid repeated downloads, you can use the `--offline` (or `-o`) flag.

**What happens in offline mode:**
- The script **does not** clone or update the `buildroot` repository.
- It **does not** run `git fetch` or `git pull` for the main repository.
- It **validates** that the local `buildroot` directory exists and is a Git repository.
- It **checks** that the requested branch is available locally (and switches to it if needed).
- If `buildroot` is missing or the branch does not exist locally, the script **fails immediately**.

**Important prerequisites for offline mode:**
1. **Manual clone of `buildroot`** – you must have the repository already checked out in the script’s directory (e.g., `./buildroot/`).
2. **Pre‑filled source cache** – Buildroot downloads external sources into `dl/` during the build.
   For a truly offline build, you need to have all required source archives already present in `dl/`.
   (You can prepare this cache by running a normal online build once, or by manually placing the archives.)

**Example:**
```bash
# Prepare the environment (online, once)
git clone https://github.com/MacroGroup/buildroot.git -b macro
# (Optional) run a full build to populate dl/ cache

# Later, offline build:
./ds-rk35xx-evb.sh -b ds-rk3568-evb --offline
```

If the script attempts to download anything during the offline build, it will fail – make sure your `dl/` cache is complete.

## Notes
- **Ensure you have at least 50 GB of free disk space** for the build.
- **Build times vary significantly** (30 minutes to several hours) depending on hardware specifications
- **All output images are ready for direct writing to SD cards** using tools like:
  - `dd` (command-line)
  - [BalenaEtcher](https://www.balena.io/etcher/) (graphical interface)
- **Offline builds** require manual preparation of the `buildroot` repository and the `dl/` source cache – the script itself does not download anything when `--offline` is used.
