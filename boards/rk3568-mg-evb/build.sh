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
ROOT=$BASE/../..
OUTPUT=$ROOT/output/rk3568-mg-evb

#
#
#

exit 0
