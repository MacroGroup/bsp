#!/bin/bash

if [ $(id -u) == "0" ]; then
	echo "This must be executed without root privilegies!"
	exit 1
fi

for i in git make; do
	if ! which $i >/dev/null 2>&1; then
		echo "Program \"$i\" does not exists!"
		exit 1
	fi
done

ROOT=$(dirname -- $(readlink -f -- "$0"))
cd $ROOT

git fetch || exit 1

UPSTREAM="origin/master"
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse $UPSTREAM)
BASE=$(git merge-base @ $UPSTREAM)

if [ $LOCAL != $REMOTE ]; then
	if [ $LOCAL = $BASE ]; then
		echo "The local BSP branch lags behind the remote one!"
		echo "Do a 'git pull' first, then re-run $0."
	elif [ $REMOTE = $BASE ]; then
		echo "Local BSP branch overtakes remote! Probaly needs a push."
	else
		echo "Local and remote BSP branches are diverge!"
	fi
	exit 1
fi

REV=1ba1ada654

git -C buildroot pull origin macro 2>/dev/null || git clone https://github.com/MacroGroup/buildroot.git

cd $ROOT/buildroot
git checkout $REV || exit 1

OUTPUT=$ROOT/output/ds-rk3568-evb
make defconfig BR2_DEFCONFIG=configs/diasom_rk3568_evb_defconfig O=$OUTPUT || exit 1

cd $OUTPUT
make

exit 0
