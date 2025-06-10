# Boot Image Build System for MacroGroup Modules

This repository contains scripts for creating boot images used with debug boards based on [MacroGroup](https://macrogroup.ru/) [DiaSom modules](https://diasom.ru/).

## Build System Components
*(Component versions may vary per board)*
- [barebox](https://barebox.org/) 2025.04.0
- [buildroot](https://buildroot.org/) 2025.02
- [Linux kernel](https://kernel.org/) 6.14

---

## Building Images

### For DS-IMX8M-EVB:
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
./ds-imx8m-evb.sh
```
SD-card image created after successful build in the output/ds-imx8m-evb/images directory.

### For DS-RK3568-EVB, DS-RK3568-SMARC-EVB or DS-RK3588-EVB:
```bash
git clone https://github.com/MacroGroup/bsp.git
cd bsp
./ds-rk35xx-evb.sh
```
SD-card image created after successful build in the output/ds-rk35xx-evb/images directory.

## Notes
⏱️ Build times vary significantly (30 mins - several hours) depending on hardware
💾 Output images ready for SD card writing with `dd` or [BalenaEtcher](https://www.balena.io/etcher/)
