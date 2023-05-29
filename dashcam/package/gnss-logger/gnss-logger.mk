################################################################################
#
# gnss-logger
#
################################################################################

GNSS_LOGGER_VERSION = 0.1.19
GNSS_LOGGER_SITE = https://github.com/streamingfast/gnss-logger/releases/download/v$(GNSS_LOGGER_VERSION)
GNSS_LOGGER_SOURCE = gnss-logger_$(GNSS_LOGGER_VERSION)_Linux_arm64.tar.gz
GNSS_LOGGER_STRIP_COMPONENTS = 0

define GNSS_LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/gnsslogger $(TARGET_DIR)/opt/dashcam/bin
endef

define GNSS_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/gnss-logger/gnss-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/gnss-logger.service
endef

$(eval $(generic-package))
