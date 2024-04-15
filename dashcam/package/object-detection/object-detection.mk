################################################################################
#
# object-detection
#
################################################################################

OBJECT_DETECTION_VERSION = 4.4.26
OBJECT_DETECTION_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/object-detection/files
OBJECT_DETECTION_SITE_METHOD = local

define OBJECT_DETECTION_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 644 $(@D)/detect_hdc.py \
		$(TARGET_DIR)/opt/dashcam/bin/detect_hdc.py
	$(INSTALL) -D -m 644 $(@D)/image.py \
		$(TARGET_DIR)/opt/dashcam/bin/image.py
	$(INSTALL) -D -m 644 $(@D)/sqlite.py \
		$(TARGET_DIR)/opt/dashcam/bin/sqlite.py
	$(INSTALL) -D -m 644 $(@D)/n800_1x2_float16.tflite \
		$(TARGET_DIR)/opt/dashcam/bin/n800_1x2_float16.tflite
	$(INSTALL) -D -m 644 $(@D)/n800_2x2_float16.tflite \
		$(TARGET_DIR)/opt/dashcam/bin/n800_2x2_float16.tflite
	$(INSTALL) -D -m 644 $(@D)/object-detection.service \
		$(TARGET_DIR)/usr/lib/systemd/system/object-detection.service
endef

$(eval $(generic-package))
