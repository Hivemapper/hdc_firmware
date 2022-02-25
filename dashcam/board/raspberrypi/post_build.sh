#!/bin/sh

set -eu

# Copy the public certificates to the target dir.
install -D -m 0644 ${BR2_EXTERNAL_DASHCAM_PATH}/board/raspberrypi/pki/dev/keyring/cert.pem ${TARGET_DIR}/etc/rauc/keyring/

# If we haven't generated SSH keys for the target yet do so now.  If they're
# already there this won't overwrite them.
ssh-keygen -A -f ${TARGET_DIR}

# Make sure any SSH private keys do not have read (or any) permissions.
chmod go-rwx \
  ${TARGET_DIR}/etc/ssh/ssh_host_dsa_key \
  ${TARGET_DIR}/etc/ssh/ssh_host_ecdsa_key \
  ${TARGET_DIR}/etc/ssh/ssh_host_ed25519_key \
  ${TARGET_DIR}/etc/ssh/ssh_host_rsa_key

# Populate version info.
rm -f ${TARGET_DIR}/etc/version.json
cat >> ${TARGET_DIR}/etc/version.json << EOF
{
  "branch": "$(git -C ${BR2_EXTERNAL_DASHCAM_PATH} branch --show-current)"
  "build_date": "$(date)"
  "hash": "$(git -C ${BR2_EXTERNAL_DASHCAM_PATH} rev-parse --short HEAD)"
}
EOF

# Install our BIT script.
install -D -m 0754 ${BR2_EXTERNAL_DASHCAM_PATH}/bootbit/bootbit ${TARGET_DIR}/usr/bin/