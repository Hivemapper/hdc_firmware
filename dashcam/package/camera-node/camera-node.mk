################################################################################
#
# camera-node
#
################################################################################

CAMERA_NODE_VERSION = 09b5d7a92f34ffd00642387b9e83d4e05f03f430
CAMERA_NODE_SITE = git@github.com:Hivemapper/odc-api.git
CAMERA_NODE_SITE_METHOD = git
CAMERA_NODE_DEPENDENCIES = host-nodejs nodejs

# Define NPM for other packages to use
# $(NPM) does not work. ncc will build incorrectly.
NPM_HOST = $(TARGET_CONFIGURE_OPTS) \
	LDFLAGS="$(NODEJS_LDFLAGS)" \
	LD="$(TARGET_CXX)" \
	$(HOST_DIR)/bin/npm

define CAMERA_NODE_BUILD_CMDS
	echo $(NPM_HOST)
	rm -rf $(@D)/node_modules

	# This works because the only arm64 binary we use is
	# sqlite3, which is not used by ncc.  All other node
	# modules are pure javascript and are not affected by
	# --arch.
	$(NPM_HOST) install --arch=arm64 --prefix $(@D)
	# temporary until we update odc-api
	$(NPM_HOST) update --arch=arm64 --prefix $(@D) sqlite3
	$(NPM_HOST) run --prefix $(@D) compile-gh --camera=hdc
endef

define CAMERA_NODE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 644 $(@D)/compiled/odc-api-hdc.js \
		$(TARGET_DIR)/opt/dashcam/bin/dashcam-api.js

	mkdir -p $(TARGET_DIR)/opt/dashcam/bin/build/Release
	$(INSTALL) -D -m 644 $(@D)/compiled/build/Release/node_sqlite3.node $(TARGET_DIR)/opt/dashcam/bin/build/Release

	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/camera-node/files/camera-node.service \
		$(TARGET_DIR)/usr/lib/systemd/system/camera-node.service
endef

$(eval $(generic-package))