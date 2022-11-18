################################################################################
#
# camera-api
#
################################################################################

CAMERA_API_VERSION = d8ee0e4a2e88ce5e6409780f006a9d1a6a0c4e19

CAMERA_API_SITE = $(call github,CapableRobot,capable_camera_firmware,$(CAMERA_API_VERSION))
CAMERA_API_DEPENDENCIES = host-zig-x86-64

define CAMERA_API_BUILD_CMDS
  # zig installs to a bin directory by default, so that's why we don't prefix to dashcam/bin.
	$(BUILD_DIR)/host-zig-x86-64-*/zig build install --build-file $(@D)/build.zig --prefix $(TARGET_DIR)/opt/dashcam/
endef

define CAMERA_API_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-api/camera-api.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-api.service
endef

$(eval $(generic-package))
