#!/bin/bash
#
# This script installs requires and some optional packages in order to build
# using Buildroot and also to run companion scripts.
#
# This is expected to run on a Debian based system since we're using apt to do
# the install.  We use apt-get install here so that may have the effect of
# upgrading packages, so use this script with care.
#
# You may also just want to use this script for reference and manually install
# packages if you don't want to turn the whole thing over to this script.

ERROR_USAGE=1
ERROR_OPTIONS=2
ERROR_NOT_SU=3

SCRIPT_PATH=`realpath $0`
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename ${SCRIPT_PATH}`

DEFAULT_INSTALL_OPTIONAL="false"

INSTALL_OPTIONAL=${DEFAULT_INSTALL_OPTIONAL}

usage()
{
  echo "${SCRIPT_NAME} [OPTIONS]"
  echo ""
  echo "Installs packages on the host system relevant to the Dashcam project."
  echo "This script must be run with root (sudo) privileges."
  echo ""
  echo "Optional:"
  echo "  -h, --help    Shows usage."
  echo "  -o, --opt     Whether to install additional optional packages.  Defaults to ${DEFAULT_INSTALL_OPTIONAL}."
  exit ${ERROR_USAGE}
}

PARSED=`getopt --options=ho --longoptions=help,opt --name "${SCRIPT_NAME}" -- "$@"`
eval set -- "$PARSED"

while true; do
  case "$1" in
    -h|--help)
      # Usage exits.
      usage
      ;;
    -o|--opt)
      INSTALL_OPTIONAL="true"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Programming error"
      exit ${ERROR_OPTIONS}
      ;;
  esac
done

if [[ $(id -u) -ne 0 ]]; then
  echo "Script must be run with root (sudo) privileges."
  exit ${ERROR_NOT_SU}
fi

echo -e "\nInstalling required packages.\n"

# This is just from the Buildroot manual:
# https://buildroot.org/downloads/manual/manual.html#requirement
# This is the minimum to build the dashcam project and use the update_http.sh script.
# 
# Install using apt-get instead of apt and use DEBIAN_FRONTEND=noninteractive
# so this script can be used by our Dockerfile.
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  sed \
  make \
  binutils \
  build-essential \
  gcc \
  g++ \
  bash \
  patch \
  gzip \
  bzip2 \
  perl \
  tar \
  cpio \
  unzip \
  rsync \
  file \
  bc \
  wget \
  git \
  python3 \
  cmake \
  curl \
  jq \
  qtbase5-dev

if [[ ${INSTALL_OPTIONAL} == "true" ]]; then
  echo -e "\nInstalling optional packages.\n"

  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3-pip \
    python3-venv \
    qt5-default
fi

echo -e "\nSetup complete."
