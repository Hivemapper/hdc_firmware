################################################################################
#
# onboard-updater
#
################################################################################

ONBOARD_UPDATER_VERSION = c5506cf0c53ebf44869c8b97bb0144f086502b6e
# Note that this is a private repo being accessed over SSH, so you need to have
# SSH keys setup for BitBucket.
ONBOARD_UPDATER_SITE = ssh://git@bitbucket.org/chr1sniessl/onboardupdater.git
ONBOARD_UPDATER_SITE_METHOD = git
ONBOARD_UPDATER_DEPENDENCIES = python-transitions
ONBOARD_UPDATER_SETUP_TYPE = setuptools

define ONBOARD_UPDATER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/onboard-updater/onboard-updater.service \
		$(TARGET_DIR)/usr/lib/systemd/system/onboard-updater.service
endef

$(eval $(python-package))