#!/bin/bash

# This is the semantic version of the software.  You should change this when
# producing production builds after a change.  The way this is written though,
# the builder could set the environment variable and this won't override it.
[[ -z "${SEMANTIC_VERSION}" ]] && SEMANTIC_VERSION="0.22.10.01-beta Apis"

set -eu

# The only way in Buildroot we can figure out what configuration we are working with is by
# having the path of this script route through the symlinked board/config directories, and
# then pulling the directory name out of the path.  So BOARD_NAME in that case
# may be "raspberrypicm4io_prod_64" for example.
BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"

IS_64=0
[[ ${BOARD_NAME} = *_64_* ]] && IS_64=1

IS_DEV=0
BUILD_TYPE="prod"
if [[ ${BOARD_NAME} = *_dev ]]; then
  IS_DEV=1
  BUILD_TYPE="dev"
fi

# Copy the custom command line file.  This command line is what is used by the 
# RPi firmware at the beginning of boot, up until the U-Boot script takes over.
install -D -m 0644 ${BR2_EXTERNAL_DASHCAM_PATH}/board/raspberrypi/cmdline.txt ${BINARIES_DIR}/rpi-firmware/cmdline.txt

# Copy the public certificates to the target dir.
install -D -m 0644 ${BR2_EXTERNAL_DASHCAM_PATH}/board/raspberrypi/pki/dev/keyring/cert.pem ${TARGET_DIR}/etc/rauc/keyring/

# Populate version info.
cat > ${TARGET_DIR}/etc/version.json <<EOF
{
  "version": "${SEMANTIC_VERSION}",
  "branch": "$(git -C ${BR2_EXTERNAL_DASHCAM_PATH} branch --show-current)",
  "build_date": "$(date)",
  "hash": "$(git -C ${BR2_EXTERNAL_DASHCAM_PATH} rev-parse --short HEAD)",
  "build_type": "${BUILD_TYPE}"
}
EOF

# Options necessary for usbmount from C.Osterwood.  Note that we give rules for vfat but I've also
# tested an ext4 thumbdrive and that mounted fine and can be written to.
sed -i "s/PrivateMounts=yes/PrivateMounts=no/g" ${TARGET_DIR}/lib/systemd/system/systemd-udevd.service
sed -i "s/FS_MOUNTOPTIONS=\"\"/FS_MOUNTOPTIONS=\"-fstype=vfat,gid=users,dmask=0007,fmask=0117\"/g" ${TARGET_DIR}/etc/usbmount/usbmount.conf
sed -i "s/sync,noexec,nodev/noexec,nodev/g" ${TARGET_DIR}/etc/usbmount/usbmount.conf

# Deconflict port 53 which dnsmasq is trying to use.  This tells systemd-resolved to not get in the way.
sed -i "s/#DNSStubListener=yes/DNSStubListener=no/g" ${TARGET_DIR}/etc/systemd/resolved.conf

# The dhcpcd service file has the wrong PID file location.  Running dhcpcd -P on the target gives
# the correct location.
sed -i "s/PIDFile=\/run\/dhcpcd.pid/PIDFile=\/var\/run\/dhcpcd\/pid/g" ${TARGET_DIR}/usr/lib/systemd/system/dhcpcd.service

# Here is where we make changes to the config.txt file for different build configurations.
CONFIG_PATH="${BINARIES_DIR}/rpi-firmware/config.txt"
if [[ ${IS_64} -ne 0 ]]; then
  sed -i "s/#arm_64bit=1/arm_64bit=1/g" ${CONFIG_PATH}
fi

if [[ ${IS_DEV} -ne 0 ]]; then
  # If we haven't generated SSH keys for the target yet do so now.  If they're
  # already there this won't overwrite them.
  ssh-keygen -A -f ${TARGET_DIR}

  # Make sure any SSH private keys do not have read (or any) permissions.
  chmod go-rwx \
    ${TARGET_DIR}/etc/ssh/ssh_host_dsa_key \
    ${TARGET_DIR}/etc/ssh/ssh_host_ecdsa_key \
    ${TARGET_DIR}/etc/ssh/ssh_host_ed25519_key \
    ${TARGET_DIR}/etc/ssh/ssh_host_rsa_key
else
  rm -rf ${TARGET_DIR}/etc/ssh
fi

# 64-bit doesn't yet support the camera-api package so make sure the BIT doesn't
# look for it.
if [[ ${IS_64} -ne 0 ]]; then
  sed -i "s/IGNORE_CCF=0/IGNORE_CCF=1/g" ${TARGET_DIR}/opt/dashcam/bin/bootbit.sh
fi
