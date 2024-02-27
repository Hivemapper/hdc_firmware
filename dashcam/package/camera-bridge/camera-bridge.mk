################################################################################
#
# camera-bridge
#
################################################################################

CAMERA_BRIDGE_VERSION = dbaea578be73fca997c9f068568c5c9691abcee1
CAMERA_BRIDGE_SITE = git@github.com:Hivemapper/camera_bridge.git
CAMERA_BRIDGE_SITE_METHOD = git
CAMERA_BRIDGE_CONF_OPTS = -DENABLE_OPENCV=0 -DCMAKE_INSTALL_PREFIX="/opt/dashcam"\
                          -DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"

# Looks like the camera-bridge links against libjpeg but the best way to provide
# this is with the jpeg-turbo package.
CAMERA_BRIDGE_DEPENDENCIES = boost libcamera jpeg-turbo json-for-modern-cpp

define CAMERA_BRIDGE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera-bridge.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-bridge.service
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera_bridge.sh \
		$(TARGET_DIR)/opt/dashcam/bin/camera_bridge.sh
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera_bridge_config.json \
		$(TARGET_DIR)/opt/dashcam/bin/camera_bridge_config.json
endef

$(eval $(cmake-package))
$(eval $(host-meson-package))
