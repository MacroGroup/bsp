#!/bin/bash

if [ $(id -u) == "0" ]; then
	echo "This must be executed without root privilegies!"
	exit 1
fi

check_prog()
{
	if ! which $1 >/dev/null 2>&1; then
		echo "Program \"$1\" does not exists!"
		exit 1
	fi
}

check_prog git

BASE=$(dirname -- $(readlink -f -- "$0"))
ROOT=$BASE/..
OUTPUT=$ROOT/output/rk3568-mg-evb

cd $ROOT
git -C buildroot pull origin macro 2>/dev/null || git clone https://github.com/MacroGroup/buildroot.git

cd $ROOT/buildroot
git checkout macro || exit 1
make defconfig BR2_DEFCONFIG=configs/rk3568_mg_evb_defconfig O=$OUTPUT
make O=$OUTPUT

exit 0
