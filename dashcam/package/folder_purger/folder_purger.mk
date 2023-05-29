################################################################################
#
# FOLDER_PURGER
#
################################################################################

FOLDER_PURGER_VERSION = 0.1.1
FOLDER_PURGER_SITE = https://github.com/streamingfast/folder-purger/releases/download/v$(FOLDER_PURGER_VERSION)
FOLDER_PURGER_SOURCE = folder-purger_$(FOLDER_PURGER_VERSION)_Linux_arm64.tar.gz
FOLDER_PURGER_STRIP_COMPONENTS = 0

define FOLDER_PURGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/folder-purger $(TARGET_DIR)/opt/dashcam/bin
endef

define FOLDER_PURGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/folder_purger/folder_purger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/folder_purger.service
endef

$(eval $(generic-package))
