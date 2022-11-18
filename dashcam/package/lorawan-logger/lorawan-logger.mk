################################################################################
#
# lorawan-logger
#
################################################################################

LORAWAN_LOGGER_VERSION = 1.0.0
LORAWAN_LOGGER_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/lorawan-logger/files
LORAWAN_LOGGER_SITE_METHOD = local

define LORAWAN_LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 744 $(@D)/lorawan-logger $(TARGET_DIR)/opt/dashcam/bin
endef

define LORAWAN_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/lorawan-logger/lorawan-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/lorawan-logger.service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/lorawan-logger/lorawan.conf \
		$(TARGET_DIR)/opt/dashcam/cfg/lorawan.conf
endef

$(eval $(generic-package))
