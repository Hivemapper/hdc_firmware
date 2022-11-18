################################################################################
#
# led-controller
#
################################################################################

LED_CONTROLLER_VERSION = 1e01a55aaecc68df1e138dfd56f47833cd6ae031
LED_CONTROLLER_SITE = ssh://git@bitbucket.org/chr1sniessl/capable_camera_firmware-mirror.git
LED_CONTROLLER_SITE_METHOD = git
LED_CONTROLLER_CONF_OPTS = -DCMAKE_INSTALL_PREFIX="/opt/dashcam" \
						-DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"
LED_CONTROLLER_DEPENDENCIES = boost json-for-modern-cpp
LED_CONTROLLER_MAKE_OPTS = led-controller

define LED_CONTROLLER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/led-controller/led-controller.service \
		$(TARGET_DIR)/usr/lib/systemd/system/led-controller.service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/led-controller/led-controller-config.txt \
		$(TARGET_DIR)/opt/dashcam/led-controller-config.txt
endef

$(eval $(cmake-package))
