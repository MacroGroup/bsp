# Boot Image Build System for MacroGroup Modules

This repository contains scripts for creating boot images used with debug boards based on [MacroGroup](https://macrogroup.ru/) [DiaSom modules](https://diasom.ru/).

## Build System Components
*(Component versions may vary per board)*
- **[barebox](https://barebox.org/) 2026.01.0+** (bootloader)
- **[buildroot](https://buildroot.org/) 2025.11+** (root filesystem generator)
- **[linux](https://kernel.org/) 6.18+** (Linux kernel)

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

## Notes
- **Ensure you have at least 50 GB of free disk space** for the build.
- **Build times vary significantly** (30 minutes to several hours) depending on hardware specifications
- **All output images are ready for direct writing to SD cards** using tools like:
  - `dd` (command-line)
  - [BalenaEtcher](https://www.balena.io/etcher/) (graphical interface)
