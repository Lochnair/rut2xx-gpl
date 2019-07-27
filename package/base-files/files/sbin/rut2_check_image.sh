#!/bin/sh

NAME=`basename $0`
FW_MODEL="RUT2"
validate="1"


check_support() {
	local file_size=`wc -c <$FIRMWARE`
	local model_offset=$((file_size - 34))
	local fw_model=`dd if=$FIRMWARE bs=1 skip=$model_offset count=4 2>/dev/null`
	local rev_from_offset=$((file_size - 30))
	local hw_rev_from=`dd if=$FIRMWARE bs=1 skip=$rev_from_offset count=4 2>/dev/null | sed s/^0*//g`
	local rev_to_offset=$((file_size - 26))
	local hw_rev_to=`dd if=$FIRMWARE bs=1 skip=$rev_to_offset count=4 2>/dev/null | sed s/^0*//g`
	HW_REV=`dd if=/dev/mtdblock1 bs=1 skip=80 count=4 2>/dev/null | sed s/^0*//g`

	if [ "$fw_model" == "$FW_MODEL" ] && \
		[ "$HW_REV" -ge "$hw_rev_from" ] && \
		[ "$HW_REV" -le "$hw_rev_to" ]; then
		return 0
	else
		return 1
	fi
}

check_checksum() {
	local file_size=`wc -c <$FIRMWARE`
	local check_length=$((file_size - 16))
	local md5_calculated=`head -c $check_length $FIRMWARE 2>/dev/null | md5sum 2>/dev/null | awk '{print $1}' 2>/dev/null`
	local md5_extracted=`hexdump -s $check_length -n 16 -e '16/1 "%02x"' $FIRMWARE 2>/dev/null`
	local md5_len=${#md5_calculated}
        
        local validation_number=`dd if=$FIRMWARE bs=1 skip=63 count=1 2>/dev/null`
        local serial_number=`mnf_info sn`
	local device_flash_id=$(cat /sys/bus/spi/devices/spi0.0/flash_name)
        
        if [ "$device_flash_id" == "gd25q128" -a "$validation_number" != "$validate" ]; then
                        echo "1"
                        exit 1
		fi
        
        # patikrina serial numerio ilgi, jei 10 tai neleis irasyti senesnio fw nei RUT850_R_00.00.371
        if [ "${#serial_number}" = "10" -a "$validation_number" != "$validate" ]; then
                echo "1"
                exit 1
        fi
        
	if [ "$md5_calculated" == "$md5_extracted" ] && \
		[ "$md5_len" == "32" ]; then
		echo "$md5_calculated"
		return 0
	else
		echo "0"
		return 1
	fi
}

usage() {
	echo "$NAME support|checksum FILE"
}


if [ "$#" -lt 2 ]; then
	usage
	exit 1
fi

ACTION="$1"
FIRMWARE="$2"
RET=1
	
if [ ! -f $FIRMWARE ]; then
	echo "$FIRMWARE not found"
	exit 1
fi

if [ "$1" == "support" ]; then
	check_support
	RET=$?
elif [ "$1" == "checksum" ]; then 
	check_checksum
	RET=$?
fi

return $RET
