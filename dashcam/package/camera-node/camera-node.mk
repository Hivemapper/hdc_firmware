################################################################################
#
# camera-node
#
################################################################################

CAMERA_NODE_VERSION = 4.2.6
CAMERA_NODE_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-node/files
CAMERA_NODE_SITE_METHOD = local
CAMERA_NODE_DEPENDENCIES = nodejs

define CAMERA_NODE_INSTALL_TARGET_CMDS
	#Add your node file to files and replace HELLOWORLD.js with your file's name
	$(INSTALL) -D -m 644 $(@D)/dashcam-api.js \
		$(TARGET_DIR)/opt/dashcam/bin/dashcam-api.js
	#Uncomment the command below once camera-node.service has been configured appropriately
	$(INSTALL) -D -m 644 $(@D)/camera-node.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-node.service
endef

$(eval $(generic-package))
