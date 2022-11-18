#!/bin/bash

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
[[ ${BOARD_NAME} = *_dev ]] && IS_DEV=1

GENIMAGE_FILE="genimage.cfg"
UBOOT_FILE="uboot.scr"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

cp ${BOARD_DIR}/${GENIMAGE_FILE} ${WORK_DIR}
cp ${BOARD_DIR}/${UBOOT_FILE} ${WORK_DIR}

# In 64-bit the kernel file is called Image, not zImage.  Also booting the kernel from U-Boot
# uses booti instead of bootz.
if [[ ${IS_64} -ne 0 ]]; then
  sed -i "s/\"zImage\"/\"Image\"/g" ${WORK_DIR}/${GENIMAGE_FILE}
  sed -i "s/zImage/Image/g" ${WORK_DIR}/${UBOOT_FILE}
  sed -i "s/bootz/booti/g" ${WORK_DIR}/${UBOOT_FILE}
fi

# In production we don't run a console on the TTY so remove it from the kernel
# boot arguments.  Don't try to remove the UART0 console since if we do that that
# seems to open the TTY again.  Weird.
if [[ ${IS_DEV} -eq 0 ]]; then
  sed -i "s/console=tty1 //g" ${WORK_DIR}/${UBOOT_FILE}
fi

# The buildroot method for creating a U-Boot script from a source seems to
# produce a binary SCR file and doesn't run.  So easy enough for us to do it.
mkimage -A arm -O linux -T script -C none \
  -n "${WORK_DIR}/${UBOOT_FILE}" \
  -d "${WORK_DIR}/${UBOOT_FILE}" \
  "${BINARIES_DIR}/boot.scr.uimg"

GENIMAGE_CFG="${WORK_DIR}/${GENIMAGE_FILE}"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${WORK_DIR}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

# Generate a RAUC update bundle for the root filesystem.
[ -e ${BINARIES_DIR}/update.raucb ] && rm -rf ${BINARIES_DIR}/update.raucb
[ -e ${BINARIES_DIR}/rauc ] && rm -rf ${BINARIES_DIR}/rauc
mkdir -p ${BINARIES_DIR}/rauc

cat >> ${BINARIES_DIR}/rauc/manifest.raucm << EOF
[update]
compatible=dashcam-rpi
version=tbd

[bundle]
format=verity

[image.boot]
filename=boot.vfat

[image.rootfs]
filename=rootfs.squashfs
EOF

# These have to be hardlinks -- symlinks will fail when RAUC goes to generate
# the signature.
ln -L ${BINARIES_DIR}/boot.vfat ${BINARIES_DIR}/rauc/boot.vfat
ln -L ${BINARIES_DIR}/rootfs.squashfs ${BINARIES_DIR}/rauc/rootfs.squashfs

${HOST_DIR}/bin/rauc bundle \
	--cert ${BOARD_DIR}/pki/dev/keyring/cert.pem \
	--key ${BOARD_DIR}/pki/dev/private/key.pem \
	${BINARIES_DIR}/rauc/ \
	${BINARIES_DIR}/update.raucb
	
echo -e "\nBuild complete."
if [[ ${IS_DEV} -ne 0 ]]; then
  echo -e "\nWarning: this is a DEVELOPMENT build and not suitable for production!"
fi
