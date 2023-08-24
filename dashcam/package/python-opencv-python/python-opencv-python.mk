################################################################################
#
# python-opencv-python
#
################################################################################

PYTHON_OPENCV_PYTHON_VERSION = 4.5.5.64
PYTHON_OPENCV_PYTHON_SOURCE = opencv-python-$(PYTHON_OPENCV_PYTHON_VERSION).tar.gz
PYTHON_OPENCV_PYTHON_SITE = https://files.pythonhosted.org/packages/32/72/03747a6820bc970aeb0b89e653d1084068ac1ed606a83d8b5ac6fc237c14
PYTHON_OPENCV_PYTHON_SETUP_TYPE = setuptools
PYTHON_OPENCV_PYTHON_LICENSE = Apache-2.0
PYTHON_OPENCV_PYTHON_LICENSE_FILES = LICENSE
PYTHON_OPENCV_PYTHON_DEPENDENCIES = readline python-distro python-scikit-build python-wheel

$(eval $(python-package))
$(eval $(host-autotools-package))