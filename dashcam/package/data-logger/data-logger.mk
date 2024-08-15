################################################################################
#
# data-logger
#
################################################################################

DATA_LOGGER_VERSION = a51e746b0ddf5bc8ec0fe2342a743f466a06568d # Release 1.5.8
DATA_LOGGER_SITE = https://github.com/Hivemapper/hivemapper-data-logger.git
DATA_LOGGER_SITE_METHOD = git
DATA_LOGGER_GOLANG_BUILD_TARGETS += ./cmd/datalogger
DATA_LOGGER_GOLANG_INSTALL_BINS += datalogger
DATA_LOGGER_GOMOD = ./cmd/datalogger

DATA_LOGGER_PRE_BUILD_HOOKS += DATA_LOGGER_CUSTOM_PRE_BUILD


# Fixes the go.mod to point to the correct gnss-controller commit
# https://github.com/Hivemapper/gnss-controller/pull/4/commits/01235228b063afaf3e1961008454c959ad6c6044
# This is a temporary solution until we merge the above PR to main
# and have an agreed upon stable branch for HDC.
define DATA_LOGGER_CUSTOM_PRE_BUILD
    echo "Running custom pre-build steps for golang-package"
	cd $(@D) && \
	{\
		pwd; \
		sed -i 's/replace github\.com\/Hivemapper\/gnss-controller.*//g' go.mod; \
		sed -i 's/v1\.0\.3-0\.20240402232423-1de9f3a3a7f8/v1\.0\.3-0\.20240514192901-01235228b063/g' go.mod; \
		$(GO_BIN) get github.com/Hivemapper/hivemapper-data-logger/cmd/datalogger; \
		$(GO_BIN) mod vendor; \
	}
endef

define DATA_LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/bin/data-logger $(TARGET_DIR)/opt/dashcam/bin/datalogger
endef

define DATA_LOGGER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/data-logger/data-logger.service \
		$(TARGET_DIR)/usr/lib/systemd/system/data-logger.service
endef

$(eval $(golang-package))