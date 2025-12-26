# Boot Image Build System for MacroGroup Modules

This repository contains scripts for creating boot images used with debug boards based on [MacroGroup](https://macrogroup.ru/) [DiaSom modules](https://diasom.ru/).

## Build System Components
*(Component versions may vary per board)*
- **[barebox](https://barebox.org/) 2025.12.0+** (bootloader)
- **[buildroot](https://buildroot.org/) 2025.11+** (root filesystem generator)
- **[linux](https://kernel.org/) 6.18+** (Linux kernel)

---

## Building Images

### For DS-IMX8M-EVB:
$\color{red}{\text{Note: Building with host GCC>=15 currently is not possible!}}$
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
./ds-imx8m-evb.sh
```
SD-card image created after successful build in the output/ds-imx8m-evb/images directory.

### For DS-RK3568-EVB or DS-RK3588-BTB-EVB:
$\color{red}{\text{Note: Building with host GCC>=15 currently is not possible!}}$
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
./ds-rk35xx-evb.sh
```
SD-card image created after successful build in the output/ds-rk35xx-evb/images directory.

## Notes

- **Ensure you have at least 50 GB of free disk space** for the build.
- **Build times vary significantly** (30 minutes to several hours) depending on hardware specifications
- **All output images are ready for direct writing to SD cards** using tools like:
  - `dd` (command-line)
  - [BalenaEtcher](https://www.balena.io/etcher/) (graphical interface)
