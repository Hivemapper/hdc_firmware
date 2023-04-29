################################################################################
#
# camera-bridge
#
################################################################################

CAMERA_BRIDGE_VERSION = bc71254d985f18d7b0ab08cb390dea0f9fb8fc42
CAMERA_BRIDGE_SITE = git@github.com:Hivemapper/capable_camera_firmware.git
CAMERA_BRIDGE_SITE_METHOD = git
CAMERA_BRIDGE_CONF_OPTS = -DENABLE_OPENCV=0 -DCMAKE_INSTALL_PREFIX="/opt/dashcam"\
                          -DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"

# Looks like the camera-bridge links against libjpeg but the best way to provide
# this is with the jpeg-turbo package.
CAMERA_BRIDGE_DEPENDENCIES = boost libcamera jpeg-turbo json-for-modern-cpp
CAMERA_BRIDGE_SUBDIR = camera

define CAMERA_BRIDGE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera-bridge.timer \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-bridge.timer
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera-bridge.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-bridge.service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera-preview.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-preview.service
endef

$(eval $(cmake-package))
