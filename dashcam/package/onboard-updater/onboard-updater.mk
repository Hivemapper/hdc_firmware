################################################################################
#
# onboard-updater
#
################################################################################

ONBOARD_UPDATER_VERSION = 7b5cf60acde9c68a39cacf3dd762251381a2edf1
ONBOARD_UPDATER_SITE = $(call github,cshaw9-rtr,onboardupdater,$(ONBOARD_UPDATER_VERSION))
ONBOARD_UPDATER_DEPENDENCIES = python-transitions
ONBOARD_UPDATER_SETUP_TYPE = setuptools

define ONBOARD_UPDATER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/onboard-updater/onboard-updater.service \
		$(TARGET_DIR)/usr/lib/systemd/system/onboard-updater.service
endef

$(eval $(python-package))