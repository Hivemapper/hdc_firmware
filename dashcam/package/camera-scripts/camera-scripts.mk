################################################################################
#
# camera-scripts
#
################################################################################

CAMERA_SCRIPTS_VERSION = 3966d2c8e7e6885514020e435448b481ca0c0410
CAMERA_SCRIPTS_SITE = ssh://git@bitbucket.org/chr1sniessl/capable_camera_firmware-mirror.git
CAMERA_SCRIPTS_SITE_METHOD = git
CAMERA_SCRIPTS_SUBDIR = scripts

define CAMERA_SCRIPTS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/scripts/* $(TARGET_DIR)/opt/dashcam/bin
endef

$(eval $(generic-package))
