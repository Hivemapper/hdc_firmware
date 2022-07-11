################################################################################
#
# camera-bridge
#
################################################################################

CAMERA_BRIDGE_VERSION = 7351cccc82f65263142312e5e25e5dcac9c9e590
CAMERA_BRIDGE_SITE = $(call github,CapableRobot,capable_camera_firmware,$(CAMERA_BRIDGE_VERSION))
CAMERA_BRIDGE_CONF_OPTS = -DENABLE_OPENCV=0 -DCMAKE_INSTALL_PREFIX="/opt/dashcam"\
                          -DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"
# Looks like the camera-bridge links against libjpeg but the best way to provide
# this is with the jpeg-turbo package.
CAMERA_BRIDGE_DEPENDENCIES = boost libcamera jpeg-turbo json-for-modern-cpp
CAMERA_BRIDGE_SUBDIR = camera

define CAMERA_BRIDGE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-bridge/camera-bridge.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-bridge.service
endef

$(eval $(cmake-package))
