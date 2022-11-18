#!/bin/bash
#
# Performs the flashing of a Raspberry Pi with our disk image, with some basic
# safety checks to make sure we're flashing a Pi.

set -euo pipefail

ERROR_USAGE=1
ERROR_OPTIONS=2
ERROR_LSBLK_ERROR=3
ERROR_NO_BLOCK_DEVICES=4
ERROR_PI_DEVICE_NOT_FOUND=5
ERROR_RPI_BOOT_NOT_FOUND=6
ERROR_DISK_IMAGE_NOT_FOUND=7

SCRIPT_PATH=`realpath $0`
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename ${SCRIPT_PATH}`

DEVICE="unset"

usage()
{
  echo "${SCRIPT_NAME} device [OPTIONS]"
  echo ""
  echo "Required:"
  echo "  device        Name of the device to flash.  e.g. sda"
  echo ""
  echo "Optional:"
  echo "  -h, --help    Shows usage."
  exit ${ERROR_USAGE}
}

PARSED=`getopt --options=h: --longoptions=help --name "${SCRIPT_NAME}" -- "$@"`
eval set -- "$PARSED"

while true; do
  case "$1" in
    -h|--help)
      # Usage exits.
      usage
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Programming error"
      exit ${ERROR_OPTIONS}
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage
fi

DEVICE=$1

RPI_BOOT_PATH=$(realpath ${SCRIPT_DIR}/..)/output/host/bin/rpiboot
if [[ ! -f ${RPI_BOOT_PATH} ]]; then
  echo "Error: ${RPI_BOOT_PATH} not found!"
  exit ${ERROR_RPI_BOOT_NOT_FOUND}
fi

echo -e "Installing temporary bootloader...\n"
sudo ${RPI_BOOT_PATH}

# On my system it seems to take less than 3 seconds, but add some headroom to that.
RPI_BOOT_SLEEP_TIME_S=5
echo -e "\nWaiting ${RPI_BOOT_SLEEP_TIME_S} seconds for device to mount..."
sleep ${RPI_BOOT_SLEEP_TIME_S}

# This is the part where we confirm that the user specified device (e.g. sda)
# actually has a RPi connected to it.  For lsblk, "8" means sd devices.
DEVICES=$(lsblk -I 8 --json -d -o NAME,VENDOR | jq -c '.')
if [[ -z ${DEVICES} ]]; then
  echo "Error: lsblk did not find any devices!"
  exit ${ERROR_LSBLK_ERROR}
fi

NUM_DEVICES=$(echo ${DEVICES} | jq '.blockdevices | length')
if [[ ${NUM_DEVICES} -eq 0 ]]; then
  echo "Error: no block devices found!"
  exit ${ERROR_NO_BLOCK_DEVICES}
fi

PI_DEVICE=$(echo ${DEVICES} | jq --arg DEVICE ${DEVICE} '.blockdevices[] | select(.vendor=="RPi-MSD-") | select(.name==$DEVICE)')
if [[ -z ${PI_DEVICE} ]]; then
  echo "Error: device '${DEVICE}' not found as a Raspberry Pi device!"
  exit ${ERROR_PI_DEVICE_NOT_FOUND}
fi

DEVICE_TO_TARGET="/dev/${DEVICE}"
echo -e "\nUnmounting device ${DEVICE_TO_TARGET}."
# Umount will give an error code if any of the partitions in the partition table
# isn't actually mounted.  We've set -x for the script to just make sure this
# command always returns 0 -- I'm ok ignoring umount errors.
sudo umount -q /dev/sda?* || /bin/true

DISK_IMAGE_PATH=$(realpath ${SCRIPT_DIR}/../output/images/sdcard.img)
if [[ ! -f ${DISK_IMAGE_PATH} ]]; then
  echo "Error: disk image not found!"
  exit ${ERROR_DISK_IMAGE_NOT_FOUND}
fi

# Getting file size in a bash script in human-convenient form isn't obvious.
# I'm using ls -lh but I'm on Ubuntu 20 and I haven't tested other Linux distributions.
IMAGE_FILE_SIZE=$(ls -lh ${DISK_IMAGE_PATH} | cut -d" " -f5)
echo -e "\nFlashing the target.  File size is ${IMAGE_FILE_SIZE}."
sudo dd if=${DISK_IMAGE_PATH} of=${DEVICE_TO_TARGET} status=progress oflag=direct bs=4M conv=fsync

# This needs to change if we change the disk layout, like adding a rescue partition
# or something.
PARTITION_TO_RESIZE=4

echo -e "\nResizing final partition.\n"
sudo parted ${DEVICE_TO_TARGET} resizepart ${PARTITION_TO_RESIZE} 100%
sudo resize2fs ${DEVICE_TO_TARGET}${PARTITION_TO_RESIZE}
sudo fsck.ext4 -p ${DEVICE_TO_TARGET}${PARTITION_TO_RESIZE}

echo -e "\nFlashing complete.  Remove the pin jumper and power cycle the target."
