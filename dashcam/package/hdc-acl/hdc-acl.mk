################################################################################
#
# HDC-ACL
#
################################################################################

HDC_ACL_VERSION = 1.1.4
HDC_ACL_SITE = https://github.com/streamingfast/hivemapper_hdc_acl/releases/download/v$(HDC_ACL_VERSION)
HDC_ACL_SOURCE = hivemapper_hdc_acl_$(HDC_ACL_VERSION)_Linux_arm64.tar.gz
HDC_ACL_STRIP_COMPONENTS = 0

define HDC_ACL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/acl $(TARGET_DIR)/opt/dashcam/bin
endef

$(eval $(generic-package))
