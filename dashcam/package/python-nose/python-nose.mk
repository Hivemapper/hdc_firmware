################################################################################
#
# python-nose
#
################################################################################

PYTHON_NOSE_VERSION = 1.3.7
PYTHON_NOSE_SOURCE = nose-$(PYTHON_NOSE_VERSION).tar.gz
PYTHON_NOSE_SITE = https://files.pythonhosted.org/packages/58/a5/0dc93c3ec33f4e281849523a5a913fa1eea9a3068acfa754d44d88107a44
PYTHON_NOSE_SETUP_TYPE = setuptools
PYTHON_NOSE_LICENSE = Apache-2.0
PYTHON_NOSE_LICENSE_FILES = LICENSE

$(eval $(python-package))
