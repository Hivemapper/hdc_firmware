#!/bin/bash
odc_version_path=./dashcam/package/camera-node/files/camera-node.service 
# Extract the firmware version from the odc-api script and transform it to X-Y-Z format
sed -n "s/.*Environment=\"ODC_VERSION=\(.*\)\".*/\1/p" $odc_version_path | sed 's/\./\-/g'
