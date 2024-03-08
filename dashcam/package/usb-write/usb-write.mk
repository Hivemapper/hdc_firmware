################################################################################
#
# usb-write
#
################################################################################

USB_WRITE_VERSION = 4.2.10
USB_WRITE_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/usb-write/files
USB_WRITE_SITE_METHOD = local

define USB_WRITE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 644 $(@D)/usb-write.py \
		$(TARGET_DIR)/opt/dashcam/bin/usb-write.py
	$(INSTALL) -D -m 644 $(@D)/usb-write.service \
		$(TARGET_DIR)/usr/lib/systemd/system/usb-write.service
endef

$(eval $(generic-package))
