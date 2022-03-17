################################################################################
#
# camera-zig
#
################################################################################

CAMERA_ZIG_VERSION = 76e09ef5ec49b81094ca6298ca524d26c45c2fa3
CAMERA_ZIG_SITE = $(call github,CapableRobot,capable_camera_firmware,$(CAMERA_ZIG_VERSION))
CAMERA_ZIG_DEPENDENCIES = host-zig-x86-64

define CAMERA_ZIG_BUILD_CMDS
  # zig installs to a bin directory by default, so that's why we don't prefix to dashcam/bin.
	zig build install --build-file $(@D)/build.zig --prefix $(TARGET_DIR)/opt/dashcam/
endef

define CAMERA_ZIG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-zig/camera-zig.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-zig.service
endef

$(eval $(generic-package))
