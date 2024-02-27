################################################################################
#
# object-detection
#
################################################################################

OBJECT_DETECTION_VERSION = 4.2.5
OBJECT_DETECTION_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/object-detection/files
OBJECT_DETECTION_SITE_METHOD = local

define OBJECT_DETECTION_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 644 $(@D)/detect_hdc.py \
		$(TARGET_DIR)/opt/dashcam/bin/detect_hdc.py
	$(INSTALL) -D -m 644 $(@D)/image.py \
		$(TARGET_DIR)/opt/dashcam/bin/image.py
	$(INSTALL) -D -m 644 $(@D)/sqlite.py \
		$(TARGET_DIR)/opt/dashcam/bin/sqlite.py
	$(INSTALL) -D -m 644 $(@D)/model.tflite \
		$(TARGET_DIR)/opt/dashcam/bin/model.tflite
	$(INSTALL) -D -m 644 $(@D)/n640_float16.tflite \
		$(TARGET_DIR)/opt/dashcam/bin/n640_float16.tflite
	$(INSTALL) -D -m 644 $(@D)/object-detection.service \
		$(TARGET_DIR)/usr/lib/systemd/system/object-detection.service
endef

$(eval $(generic-package))
