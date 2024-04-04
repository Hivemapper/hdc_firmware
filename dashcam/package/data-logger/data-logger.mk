################################################################################
#
# data-logger
#
################################################################################

DATA_LOGGER_VERSION = 134f6952c9a2f6aecebfb77bf76609e548c5f17f
DATA_LOGGER_SITE = git@github.com:Hivemapper/hivemapper-data-logger.git
DATA_LOGGER_SITE_METHOD = git
DATA_LOGGER_GOLANG_BUILD_TARGETS += ./cmd/datalogger
DATA_LOGGER_GOLANG_INSTALL_BINS += datalogger
DATA_LOGGER_GOMOD = ./cmd/datalogger

define DATA_LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bin/data-logger $(TARGET_DIR)/opt/dashcam/bin/datalogger
endef

define DATA_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/data-logger/data-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/data-logger.service
endef

$(eval $(golang-package))
