#
# Copyright (C) 2011 OpenWrt.org
#

. /lib/ar71xx.sh

PART_NAME=${PART_NAME:-"firmware"}
RAMFS_COPY_DATA=/lib/ar71xx.sh

CI_BLKSZ=65536
CI_LDADR=0x80060000

tplink_get_image_hwid() {
	get_image "$@" | dd bs=4 count=1 skip=16 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

tplink_get_image_boot_size() {
	get_image "$@" | dd bs=4 count=1 skip=37 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

check_rut2_hw_rev() {
	local file_size=`wc -c <$1`
	local model_offset=$((file_size - 34))
	local rev_from_offset=$((file_size - 30))
	local rev_to_offset=$((file_size - 26))
	local fw_model=`dd if=$1 bs=1 skip=$model_offset count=4 2>/dev/null`
	local hw_rev_from=`dd if=$1 bs=1 skip=$rev_from_offset count=4 2>/dev/null | sed s/^0*//g`
	local hw_rev_to=`dd if=$1 bs=1 skip=$rev_to_offset count=4 2>/dev/null | sed s/^0*//g`
	local current_hw_rev=`dd if=/dev/mtdblock1 bs=1 skip=80 count=4 2>/dev/null | sed s/^0*//g`

	if [ "$fw_model" == "RUT2" ] && \
		[ "$current_hw_rev" -ge "$hw_rev_from" ] && \
		[ "$current_hw_rev" -le "$hw_rev_to" ]; then
		echo "1"
	else
		echo "0"
	fi
}

platform_check_image() {
	local board=$(ar71xx_board_name)
	local magic="$(get_magic_word "$1")"
	local magic_long="$(get_magic_long "$1")"

	[ "$ARGC" -gt 2 ] && return 1

	case "$board" in
	tlt-rut200)
		[ "$magic" != "0100" ] && {
			echo "Invalid image type."
			return 1
		}

		local hwid
		local imageid

		hwid=$(tplink_get_hwid $PART_NAME)
		imageid=$(tplink_get_image_hwid "$1")

		[ "$hwid" != "$imageid" ] && {
			echo "Invalid image, hardware ID mismatch, hw:$hwid image:$imageid."
			return 1
		}

		local boot_size

		boot_size=$(tplink_get_image_boot_size "$1")
		[ "$boot_size" != "00000000" ] && {
			echo "Invalid image, it contains a bootloader."
			return 1
		}
		local fw_revision=`dd if="$1" bs=1 skip=28 count=6 2>/dev/null`

		hw_rev_compatible=$(check_rut2_hw_rev $1)
		if [ "$fw_revision" != "RUT2xx" ] || \
			[ "$hw_rev_compatible" != "1" ]; then
			echo "Invalid image, not supported on this device."
			return 1
		fi

		return 0
		;;
	esac

	echo "Sysupgrade is not yet supported on $board."
	return 1
}

platform_do_upgrade() {
	default_do_upgrade "$ARGV"
}

disable_watchdog() {
	killall watchdog
	( ps | grep -v 'grep' | grep '/dev/watchdog' ) && {
		echo 'Could not disable watchdog'
		return 1
	}
}

append sysupgrade_pre_upgrade disable_watchdog
