################################################################################
#
# gpsd-and-config
#
################################################################################

GPSD_AND_CONFIG_VERSION = 1.0.0
GPSD_AND_CONFIG_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/gpsd-and-config/files
GPSD_AND_CONFIG_SITE_METHOD = local

define GPSD_AND_CONFIG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 644 $(@D)/gpsd $(TARGET_DIR)/etc/default/gpsd
endef

$(eval $(generic-package))
