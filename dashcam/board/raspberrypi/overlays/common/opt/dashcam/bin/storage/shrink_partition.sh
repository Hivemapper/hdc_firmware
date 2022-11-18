#!/bin/sh
#
# Shrink the partition to retrigger the expansion of it.
#

sh /opt/dashcam/bin/stop_all.sh
sleep 3;
sh /opt/dashcam/bin/storage/clean_data.sh
sleep 3;
umount /dev/mmcblk0p4
sleep 1;
resize2fs /dev/mmcblk0p4 17254
parted /dev/mmcblk0 resizepart 4 781MB
resize2fs /dev/mmcblk0p4
mount /dev/mmcblk0p4

