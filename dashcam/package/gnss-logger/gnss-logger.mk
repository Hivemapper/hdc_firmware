################################################################################
#
# gnss-logger
#
################################################################################

GNSS_LOGGER_VERSION = dbf14befd80bc19866b4125cefaff38dadd2d3a9
GNSS_LOGGER_SITE = ssh://git@bitbucket.org/chr1sniessl/capable_camera_firmware-mirror.git
GNSS_LOGGER_SITE_METHOD = git
GNSS_LOGGER_CONF_OPTS = -DCMAKE_INSTALL_PREFIX="/opt/dashcam" \
						-DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"
GNSS_LOGGER_DEPENDENCIES = boost json-for-modern-cpp
GNSS_LOGGER_MAKE_OPTS = gnss-logger

define GNSS_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/gnss-logger/gnss-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/gnss-logger.service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/gnss-logger/gnss-logger-config.txt \
		$(TARGET_DIR)/opt/dashcam/gnss-logger-config.txt
endef

$(eval $(cmake-package))
