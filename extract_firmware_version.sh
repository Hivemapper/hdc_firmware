#!/bin/bash

camera_node_dir=$(find output/build -maxdepth 1 -type d -name 'camera-node-*')
echo $camera_node_dir
dashcam_api_path=$camera_node_dir/compiled/odc-api-hdc.js

# Extract the firmware version from the odc-api script and transform it to X_Y_Z format
grep -m 1 "exports.API_VERSION = '" $dashcam_api_path | sed -n "s/.*'\(.*\)'.*/\1/p" | sed 's/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1_\2_\3/g'