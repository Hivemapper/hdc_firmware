################################################################################
#
# zig-aarch64
#
################################################################################

ZIG_AARCH64_VERSION = 0.8.1
ZIG_AARCH64_SOURCE = zig-linux-aarch64-$(ZIG_AARCH64_VERSION).tar.xz
ZIG_AARCH64_SITE = https://ziglang.org/download/$(ZIG_AARCH64_VERSION)

define ZIG_AARCH64_INSTALL_TARGET_CMDS
	install -D -m 0755 $(@D)/zig $(TARGET_DIR)/usr/bin
endef

$(eval $(generic-package))