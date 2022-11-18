#!/bin/bash
#
# This script can be used to setup the build configuration and perform the build
# along the lines of the README instructions.

ERROR_USAGE=1
ERROR_OPTIONS=2
ERROR_UNKNOWN_OPTIONS=3

SCRIPT_PATH=`realpath $0`
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename ${SCRIPT_PATH}`
PARENT_DIR=`realpath ${SCRIPT_DIR}/..`

DEFAULT_ARCH="32"
DEFAULT_TYPE="prod"

ARCH=${DEFAULT_ARCH}
TYPE=${DEFAULT_TYPE}

usage()
{
  echo "${SCRIPT_NAME} [OPTIONS]"
  echo ""
  echo "Sets up an output directory, build configuration, and does a build."
  echo ""
  echo "Optional:"
  echo "  -h, --help        Shows usage."
  echo "  -a, --arch ARCH   Whether to build 32 or 64 bit.  Defaults to ${DEFAULT_ARCH}."
  echo "  -t, --type TYPE   Whether to build prod or dev.  Defaults to ${DEFAULT_TYPE}."
  exit ${ERROR_USAGE}
}

PARSED=`getopt --options=ha:t: --longoptions=help,arch:type: --name "${SCRIPT_NAME}" -- "$@"`
eval set -- "$PARSED"

while true; do
  case "$1" in
    -h|--help)
      # Usage exits.
      usage
      ;;
    -a|--arch)
      ARCH="$2"
      shift 2
      ;;
    -t|--type)
      TYPE="$2"
      shift 2
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

if [[ ${ARCH} != "32" && ${ARCH} != "64" ]]; then
  echo "Architecture type ${ARCH} is unknown."
  exit ${ERROR_UNKNOWN_OPTIONS}
fi

if [[ ${TYPE} != "dev" && ${TYPE} != "prod" ]]; then
  echo "Build type ${TYPE} is unknown."
  exit ${ERROR_UNKNOWN_OPTIONS}
fi

CONFIG=""

if [[ ${ARCH} == "64" ]]; then
  if [[ ${TYPE} == "dev" ]]; then
    CONFIG="raspberrypicm4io_64_dev"
  else
    CONFIG="raspberrypicm4io_64_prod"
  fi
else
  if [[ ${TYPE} == "dev" ]]; then
    CONFIG="raspberrypicm4io_dev"
  else
    CONFIG="raspberrypicm4io_prod"
  fi
fi
CONFIG+="_dashcam_defconfig"

echo -e "Selected build configuration: ${CONFIG}"

echo -e "\nRemoving any previous output directory."
rm -rf ${PARENT_DIR}/output

echo -e "\nCreating build configuration."
make -C ${PARENT_DIR}/buildroot/ BR2_EXTERNAL=${PARENT_DIR}/dashcam O=${PARENT_DIR}/output ${CONFIG}

echo -e "\nPerforming build."
(cd ${PARENT_DIR}/output && make)
