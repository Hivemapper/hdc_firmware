################################################################################
#
# python-sympy
#
################################################################################

PYTHON_SYMPY_VERSION = 1.12
PYTHON_SYMPY_SOURCE = sympy-$(PYTHON_SYMPY_VERSION).tar.gz
PYTHON_SYMPY_SITE = https://files.pythonhosted.org/packages/e5/57/3485a1a3dff51bfd691962768b14310dae452431754bfc091250be50dd29
PYTHON_SYMPY_SETUP_TYPE = setuptools
PYTHON_SYMPY_LICENSE = MIT
PYTHON_SYMPY_LICENSE_FILES = LICENSE.txt
PYTHON_SYMPY_CPE_ID_VENDOR = pypa
PYTHON_SYMPY_CPE_ID_PRODUCT = pip

$(eval $(python-package))
