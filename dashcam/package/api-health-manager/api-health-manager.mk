################################################################################
#
# camera-node
#
################################################################################

CAMERA_NODE_VERSION = 1.0.0
CAMERA_NODE_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/api-health-manager/files
CAMERA_NODE_SITE_METHOD = local
CAMERA_NODE_DEPENDENCIES = nodejs

define CAMERA_NODE_INSTALL_TARGET_CMDS
	#Add your node file to files and replace HELLOWORLD.js with your file's name
	$(INSTALL) -D -m 644 $(@D)/health-manager.js \
		$(TARGET_DIR)/opt/dashcam/bin/health-manager.js
	#Uncomment the command below once api-health-manager.service has been configured appropriately
	$(INSTALL) -D -m 644 $(@D)/api-health-manager.service \
		$(TARGET_DIR)/usr/lib/systemd/system/api-health-manager.service
endef

$(eval $(generic-package))
