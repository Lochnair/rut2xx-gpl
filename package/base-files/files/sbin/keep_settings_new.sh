#!/bin/sh

SCRIPT_NAME=`basename $0`
CONFIG_PART=""
CONFIG_PART_DESC="config"
CONFIG_OFFSET="40960"	# 0xA000
CONFIG_LENGTH="4096"	# 0x1000
TMP_DIR="/tmp/keep_settings"
TAR_FILE="keep_settings.tar.gz"
TAR_SIZE_LENGTH="4"

config_mtd_num=`cat /proc/mtd | grep -m 1 "\"$CONFIG_PART_DESC\"" | head -c 4 | tail -c 1`
if [ -z "$config_mtd_num" ]; then
	echo "Partition '$CONFIG_PART_DESC' not found"
	return 1
else
	CONFIG_PART="/dev/mtdblock$config_mtd_num"
fi


usage() {
	echo "Reads/writes settings from/to '$CONFIG_PART_DESC' partition"
	echo "Usage: $SCRIPT_NAME COMMAND CONFIG1.SECTION1 CONFIG2.SECTION2 ..."
	echo "Supported commands:"
	echo "	backup	-	Backup specified settings to flash"
	echo "	restore	-	Restore specified settings from flash"
	echo "	check	-	Check settings from flash"
	echo "	delete	-	Detele all settings from flash"
}

read_mtd_tar() {
	local tar_file="$1"
	local ret=1
	rm -f $tar_file
	tar_size=`dd if=$CONFIG_PART bs=1 count=$TAR_SIZE_LENGTH skip=$CONFIG_OFFSET 2>/dev/null`
	if [ ! -z "$tar_size" ]; then
		tar_size=`echo "$tar_size" | sed "s/[[:space:]]//g"`
		dd if=$CONFIG_PART of=$tar_file bs=1 count=$tar_size skip=$((CONFIG_OFFSET + TAR_SIZE_LENGTH)) 2>/dev/null
		ret=$?
	fi
	return $ret
}

write_mtd_tar() {
	local tar_file="$1"
	local ret=1
	if [ ! -z "$tar_file" ]; then
		tar_size=`wc -c <$tar_file`
		if [ ! -z "$tar_size" ]; then
			printf "%0${TAR_SIZE_LENGTH}s" $tar_size | dd of=$CONFIG_PART bs=1 count=$TAR_SIZE_LENGTH seek=$CONFIG_OFFSET 2>/dev/null
			if [ $? -eq 0 ]; then
				dd if=$tar_file of=$CONFIG_PART bs=1 count=$tar_size seek=$((CONFIG_OFFSET + TAR_SIZE_LENGTH)) 2>/dev/null
				ret=$?
			fi
		fi
	fi
	return $ret
}

delete_mtd() {
	dd if=/dev/zero of=$CONFIG_PART bs=1 seek=$CONFIG_OFFSET count=$CONFIG_LENGTH 2>/dev/null
	return $?
}

backup_uci_settings() {
	local config="$1"
	local section="'""$2""'"
	local output="$3"
	local ret=1
	local uci_show=`uci show $config`
	if [ "$uci_show" == "" ]; then
		return $ret
	fi
	uci export $config > $output
	if [ $? -eq 0 ]; then
		sed -n ':s;/\(^config.*'"$section"'\)\|\(^package '"$config"'\)/{:l;p;n;/^config/bs;bl;}' $output > $output".tmp"
		ret=$?
		if [ $ret -eq 0 ]; then
			mv $output".tmp" $output
		else
			rm -f $output $output".tmp"
		fi
	fi
	return $ret
}

backup() {
	local cfgs="$@"
	local ret=1
	local backed_up=0
	if [ ! -z "$cfgs" ]; then
		mkdir "$TMP_DIR"
		cd "$TMP_DIR"
		for config in $cfgs; do
			backup_uci_settings "${config%.*}" "${config#*.}" "$TMP_DIR/$config"
			if [ $? -eq 0 ]; then
				backed_up=$((backed_up + 1))
			fi
		done
		if [ $backed_up -gt 0 ]; then
			tar -czf "$TAR_FILE" *
			if [ $? -eq 0 ]; then
				write_mtd_tar "$TMP_DIR/$TAR_FILE"
				ret=$?
			fi
		fi
		cd /
		rm -rf "$TMP_DIR"
	fi
	return $ret
}

restore() {
	local cfgs="$@"
	local ret=1
	local restored=0
	if [ ! -z "$cfgs" ]; then
		mkdir "$TMP_DIR"
		cd "$TMP_DIR"
		read_mtd_tar "$TMP_DIR/$TAR_FILE"
		if [ $? -eq 0 ]; then
			tar -xzf "$TMP_DIR/$TAR_FILE"
			if [ $? -eq 0 ]; then
				for config in $cfgs; do
					if [ -f "$TMP_DIR/$config" ]; then
						cat $config | uci import -m "${config%.*}"
						uci commit "${config%.*}"
						restored=$((restored + 1))
					else
						echo "$config not found in saved archive!"
					fi
				done
			fi
		fi
		cd /
		rm -rf "$TMP_DIR"
	fi
	if [ $restored -gt 0 ]; then
		ret=0
	fi
	return $ret
}

check() {
	local ret=1
	local ls_files
	mkdir "$TMP_DIR"
	cd "$TMP_DIR"
	read_mtd_tar "$TMP_DIR/$TAR_FILE"
	if [ $? -eq 0 ]; then
		tar -xzf "$TMP_DIR/$TAR_FILE"
		if [ $? -eq 0 ]; then
			ls_files=`ls -l | wc -l`
			if [ $ls_files -gt 1 ]; then
				echo "Backup settings detected"
				ret=0
			fi
		fi
	fi
	cd /
	rm -rf "$TMP_DIR"
	return $ret
}


case "$1" in
	"backup")
		if [ $# -lt 2 ]; then
			usage
			return 1
		fi
		shift
		backup $@
		return $?
	;;
	"restore")
		if [ $# -lt 2 ]; then
			usage
			return 1
		fi
		shift
		restore $@
		return $?
	;;
	"check")
		check
		return $?
	;;
	"delete")
		delete_mtd
		return $?
	;;
	*)
		usage
	;;
esac

return 1
