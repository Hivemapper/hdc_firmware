#!/bin/bash
set -x
camera_node_dir=$(find ../output/build -maxdepth 1 -type d -name 'camera-node-*')
echo $camera_node_dir
dashcam_api_path=$camera_node_dir/compiled/odc-api-hdc.js
echo $dashcam_api_path
# Extract the firmware version from the odc-api script and transform it to X_Y_Z format
grep -m 1 "exports.API_VERSION = '" $dashcam_api_path | sed -n "s/.*'\(.*\)'.*/\1/p" | sed 's/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1-\2-\3/g'