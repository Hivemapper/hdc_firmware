################################################################################
#
# zig-x86-64
#
################################################################################

HOST_ZIG_X86_64_VERSION = 0.8.1
HOST_ZIG_X86_64_SOURCE = zig-linux-x86_64-$(HOST_ZIG_X86_64_VERSION).tar.xz
HOST_ZIG_X86_64_SITE = https://ziglang.org/download/$(HOST_ZIG_X86_64_VERSION)

define HOST_ZIG_X86_64_INSTALL_CMDS
	install -D -m 0755 $(@D)/zig $(HOST_DIR)/usr/bin
endef

$(eval $(host-generic-package))