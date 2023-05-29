################################################################################
#
# DEBUGGER
#
################################################################################

DEBUGGER_VERSION = 0.1.9
DEBUGGER_SITE = https://github.com/streamingfast/hivemapper-hdc-debugger/releases/download/v$(DEBUGGER_VERSION)
DEBUGGER_SOURCE = hivemapper-hdc-debugger_$(DEBUGGER_VERSION)_Linux_arm64.tar.gz

DEBUGGER_STRIP_COMPONENTS = 0

define DEBUGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/debugger $(TARGET_DIR)/opt/dashcam/bin
endef

define DEBUGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/debugger/debugger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/debugger.service
endef

$(eval $(generic-package))
