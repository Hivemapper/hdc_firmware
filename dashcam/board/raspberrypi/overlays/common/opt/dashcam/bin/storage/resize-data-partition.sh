#!/bin/sh

# Script variables
EXPAND_DEVICE=/dev/mmcblk0
EXPAND_PARTITION=${EXPAND_DEVICE}p4
FLASH_SECTORS=20000
EMMC_FLAG=/mnt/data/emmc_fixed
EMMC_RESULTS_TMP=/root/emmc_results
EMMC_RESULTS=/mnt/data/emmc_results
MIN_EMMC_SPEED=15 #MB/s
EMMC_TEST_SIZE=100 #MB

get_line()
{
    # Prepare Arguments
    INPUT="$1"
    LINE_NUM=$2

    # Prepare string that will get us the line offset
    LINE_STR=$(printf "%dp" $LINE_NUM)

    # Get line and echo it to the caller
    echo "$(echo "$INPUT" | sed -n $LINE_STR)"
}

get_size_value()
{
    # Prepare arguments
    PARTITION=$1
    DF_ARGS="$2"

    # Get size information for partition
    SIZE_INFO=$(df $DF_ARGS $PARTITION | tr -s ' ' | cut -d' ' -f2)

    # Parse out information from info
    SIZE_LABEL=$(get_line "$SIZE_INFO" 1)
    SIZE_VALUE=$(get_line "$SIZE_INFO" 2)

    # Set default value and determine if the info we have is valid
    SIZE=0
    if [ $SIZE_LABEL == "1K-blocks" ] || [ $SIZE_LABEL == "Size" ]; then
        SIZE=$SIZE_VALUE
    fi

    # Echo the size to the caller
    echo $SIZE
}

emmc_speed_test()
{
    # Args
    MB="$1"

    # Use DD to measure emmc speed
    TIME_STR=$(time dd if=/dev/zero of=/mnt/data/test bs=1M count=$MB 2>&1 | grep real)
    rm /mnt/data/test

    # Massage the output of dd into something we can do math with
    TIME_MINS=$(echo $TIME_STR | awk '{print substr($2, 1, length($2)-1)}')
    TIME_SECS=$(echo $TIME_STR | awk '{print substr($3, 1, length($3)-1)}')
    SECS=$(echo "scale=2; ($TIME_MINS * 60) + $TIME_SECS" | bc)

    # Echo back MB/s
    echo "$(echo "scale=2; $MB / $SECS" | bc)"
}

do_reformat()
{
    # Ensure no data is waiting to be written
    sync

    # Resize data partition and remake filesystem with busybox defaults
    umount $EXPAND_PARTITION
    parted $EXPAND_DEVICE resizepart 4 100%
    yes | mkfs.ext4 $EXPAND_PARTITION
    e2label $EXPAND_PARTITION data
    mount $EXPAND_PARTITION

    touch $EMMC_FLAG
}

# Pull the emmc_results file to preserve the log if we change the fs.
cp $EMMC_RESULTS $EMMC_RESULTS_TMP

# Perform fsck auto-correct on partition.
# If this and the mount fails, then the flag won't be detected and
# the partition will be reformatted.
fsck -y $EXPAND_PARTITION
mount $EXPAND_PARTITION

SIZE_VALUE=$(get_size_value $EXPAND_PARTITION)
echo "Initial emmc size: $SIZE_VALUE" | tee -a $EMMC_RESULTS_TMP

# Skip inital speed test if partition is still tiny
if [ $SIZE_VALUE -ge $FLASH_SECTORS ]; then
	PRE_SPEED_TEST=$(emmc_speed_test $EMMC_TEST_SIZE)
	echo "Initial speed: $PRE_SPEED_TEST" | tee -a $EMMC_RESULTS_TMP
fi

# Check if the emmc has been fixed
if [ -f "$EMMC_FLAG" ]; then
    echo "Emmc aleady fixed" | tee -a $EMMC_RESULTS_TMP
else
    CHANGED_EMMC=1
    echo "Reformatting $EXPAND_PARTITION" | tee -a $EMMC_RESULTS_TMP
    do_reformat
    POST_SPEED_TEST=$(emmc_speed_test $EMMC_TEST_SIZE)
    echo "Post fix speed: $POST_SPEED_TEST" | tee -a $EMMC_RESULTS_TMP
    # Output partition size
    SIZE_VALUE=$(get_size_value $EXPAND_PARTITION "-h")
    echo "Post fix size: $SIZE_VALUE" | tee -a $EMMC_RESULTS_TMP
    # We changed the emmc, so copy the results back to peristent storage
    cp $EMMC_RESULTS_TMP $EMMC_RESULTS
fi

# Check and create swapfile if it doesn't exist
SWAPFILE=/mnt/data/swapfile
if [ ! -f "$SWAPFILE" ]; then
    echo "Creating swapfile at $SWAPFILE" | tee -a $EMMC_RESULTS_TMP
    dd if=/dev/zero of=$SWAPFILE bs=1M count=1024
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon $SWAPFILE
    echo "Swapfile created and activated" | tee -a $EMMC_RESULTS_TMP
else
    echo "Swapfile already exists" | tee -a $EMMC_RESULTS_TMP
    echo 10 > /proc/sys/vm/swappiness
fi
