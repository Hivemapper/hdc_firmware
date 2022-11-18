#!/bin/bash
#
# Sets up an existing working directory by creating or reusing three
# firmware builds.

set -euo pipefail

ERROR_USAGE=1
ERROR_OPTIONS=2
ERROR_NO_WORK_DIR=3
ERROR_NO_OUTPUT_DIR=4

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename ${SCRIPT_PATH})

VERSION_FILE=version.json
UPDATE_FILE=update.raucb

CLEAN=0

usage()
{
  echo "${SCRIPT_NAME} work_dir [OPTIONS]"
  echo ""
  echo "Required:"
  echo "  work_dir      Directory to hold firmware versions and output artifacts."
  echo ""
  echo "Optional:"
  echo "  -h, --help    Shows usage."
  echo "  -c, --clean   Clean the working directory before creating new firmware versions."
  exit ${ERROR_USAGE}
}

PARSED=`getopt --options=hc --longoptions=help,clean --name "${SCRIPT_NAME}" -- "$@"`
eval set -- "$PARSED"

while true; do
  case "$1" in
    -h|--help)
      # Usage exits.
      usage
      ;;
    -c|--clean)
      CLEAN=1
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

if [[ $# -ne 1 ]]; then
  echo "No working directory given."
  usage
fi

WORK_DIR=$1

if [[ ! -d ${WORK_DIR} ]]; then
  echo "Working directory does not exist: ${WORK_DIR}"
  exit ${ERROR_NO_WORK_DIR}
fi

OUTPUT_DIR="$(realpath ${SCRIPT_DIR}/../..)/output"
if [[ ! -d ${OUTPUT_DIR} ]]; then
  echo "Build output directory does not exist: ${OUTPUT_DIR}"
  echo "Please configure the project before running this program."
  exit ${ERROR_NO_OUTPUT_DIR}
fi

if [[ ${CLEAN} -ne 0 ]]; then
  echo "Cleaning working directory."
  # Let's be as targeted as we can here.  The last thing we need is to rm -rf the user's
  # home directory...
  rm -f ${WORK_DIR}/*.${VERSION_FILE} ${WORK_DIR}/*.${UPDATE_FILE}
fi

for ii in 0 1 2
do
  if [[ -f ${WORK_DIR}/${ii}.${VERSION_FILE} && -f ${WORK_DIR}/${ii}.${UPDATE_FILE} ]]; then
    echo "Reusing update bundle #${ii}."
    continue
  fi 

  echo "Building update bundle #${ii}."
  (cd ${OUTPUT_DIR} && make 2>1 1>/dev/null)
  cp ${OUTPUT_DIR}/target/etc/${VERSION_FILE} ${WORK_DIR}/${ii}.${VERSION_FILE}
  cp ${OUTPUT_DIR}/images/${UPDATE_FILE} ${WORK_DIR}/${ii}.${UPDATE_FILE}
done

exit 0
