################################################################################
#
# data-logger
#
################################################################################

DATA_LOGGER_VERSION = 1.5.3
DATA_LOGGER_SITE = https://github.com/Hivemapper/hivemapper-data-logger/releases/download/v$(DATA_LOGGER_VERSION)
DATA_LOGGER_SOURCE = hivemapper-data-logger_$(DATA_LOGGER_VERSION)_Linux_arm64.tar.gz
DATA_LOGGER_STRIP_COMPONENTS = 0

define DATA_LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/datalogger $(TARGET_DIR)/opt/dashcam/bin
endef

define DATA_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/data-logger/data-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/data-logger.service
endef

$(eval $(generic-package))