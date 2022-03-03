################################################################################
#
# onboard-updater
#
################################################################################

ONBOARD_UPDATER_VERSION = 4080ab3a9a5be2abc698d686b1f5afd1aae992b3
ONBOARD_UPDATER_SITE = $(call github,cshaw9-rtr,onboard-updater,$(ONBOARD_UPDATER_VERSION))
ONBOARD_UPDATER_SETUP_TYPE = setuptools

define ONBOARD_UPDATER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/onboard-updater/onboard-updater.service \
		$(TARGET_DIR)/usr/lib/systemd/system/onboard-updater.service
endef

$(eval $(python-package))