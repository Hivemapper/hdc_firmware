################################################################################
#
# python-transitions
#
################################################################################

PYTHON_TRANSITIONS_VERSION = 0.8.11
PYTHON_TRANSITIONS_SOURCE = transitions-$(PYTHON_TRANSITIONS_VERSION).tar.gz
PYTHON_TRANSITIONS_SITE = https://files.pythonhosted.org/packages/0b/e2/694deb6e9f8b66c6a356a738237ddec13c57ac2aaa3906e5573345bf20ea
PYTHON_TRANSITIONS_SETUP_TYPE = setuptools
PYTHON_TRANSITIONS_LICENSE = MIT
PYTHON_TRANSITIONS_LICENSE_FILES = LICENSE

$(eval $(python-package))
