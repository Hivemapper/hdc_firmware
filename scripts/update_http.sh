#!/bin/bash
#
# Writes a RAUC update bundle to the target, installs it, and reboots,
# using the production HTTP interface.
#
# Dependencies:
# - curl
# - jq

ERROR_USAGE=1
ERROR_OPTIONS=2
ERROR_NO_CURL=3
ERROR_NO_JQ=4
ERROR_BAD_STATE=5
ERROR_BAD_POST=6
ERROR_NO_UPDATE_FILE=7
ERROR_UPDATE_FAILED=8
ERROR_UPDATE_TIMEOUT=9
ERROR_REBOOT_TIMEOUT=10
ERROR_NO_CONNECTION=11
ERROR_BOOTBIT_TIMEOUT=12
ERROR_BOOTBIT_NOT_HEALTHY=13

TIMEOUT_UPDATE_S=30
# Use a long reboot time in case connecting over wifi.  Wifi on the target is the last thing to
# come up and then the host wifi needs to detect it and connect to it.
TIMEOUT_REBOOT_S=70
REBOOT_SLEEP_TIME_S=30
TIMEOUT_BOOTBIT_S=10
TIMEOUT_CONNECTION_S=0.1
PORT=8080

# Test for curl dependency.
curl --version > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error: curl not installed."
    exit ${ERROR_NO_CURL}
fi

jq --version > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Error: jq not installed."
    exit ${ERROR_NO_JQ}
fi

# Don't use 'e' here since we have a bunch of bash arithmetic that sums to 0.
# -e thinks of that as a failure.
set -uo pipefail

SCRIPT_PATH=`realpath $0`
SCRIPT_DIR=`dirname $0`
SCRIPT_NAME=`basename ${SCRIPT_PATH}`

DEFAULT_FILE_PATH="$(realpath ${SCRIPT_DIR}/..)/output/images/update.raucb"
FILE_PATH=${DEFAULT_FILE_PATH}

usage()
{
  echo "${SCRIPT_NAME} target_ip [OPTIONS]"
  echo ""
  echo "Required:"
  echo "  target_ip     IP address of the target."
  echo ""
  echo "Optional:"
  echo "  -h, --help    Shows usage."
  echo "  -f, --file    Update file to install. Defaults to ${DEFAULT_FILE_PATH}."
  exit ${ERROR_USAGE}
}

PARSED=`getopt --options=hf: --longoptions=help,file: --name "${SCRIPT_NAME}" -- "$@"`
eval set -- "$PARSED"

while true; do
  case "$1" in
    -h|--help)
      # Usage exits.
      usage
      ;;
    -f|--file)
      FILE_PATH="$2"
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

if [[ $# -ne 1 ]]; then
  echo "Error: no target_ip given."
  usage
fi

TARGET_IP="$1"

if [[ ! -f ${FILE_PATH} ]]; then
  echo "Error: upload file does not exist."
  exit ${ERROR_NO_UPDATE_FILE}
fi

# Test for connectivity.
CODE=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -o /dev/null -w "%{http_code}" -X GET http://${TARGET_IP}:${PORT}/status)
if [[ $? -ne 0 || ${CODE} -ne 200 ]]; then
  echo "Error: unable to get status from target."
  echo "Ensure you are connected to the target on IP of ${TARGET_IP}."
  exit ${ERROR_NO_CONNECTION}
fi

function get_state()
{
  local JSON=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/status)
  if [[ $? -ne 0 ]]; then
    echo ""
  fi
  local STATE=$(echo ${JSON} | jq .state)
  echo ${STATE}
}

function get_rauc_state()
{
  local JSON=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/status)
  if [[ $? -ne 0 ]]; then
    echo ""
  fi
  local STATE=$(echo ${JSON} | jq .rauc_state)
  echo ${STATE}
}

function get_boot_state()
{
  local JSON=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/status)
  if [[ $? -ne 0 ]]; then
    echo ""
  fi
  local STATE=$(echo ${JSON} | jq .boot_state)
  echo ${STATE}
}

function get_last_error()
{
  local JSON=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/status)
  if [[ $? -ne 0 ]]; then
    echo ""
  fi
  local LAST_ERROR=$(echo ${JSON} | jq .last_error)
  echo ${LAST_ERROR}
}

function get_time_s()
{
  echo $(date +%s)
}

STATE=$(get_state) 
echo "Target state: ${STATE}"
if [[ ${STATE} != \"ready\" && ${STATE} != \"failed\" ]]; then
  echo "Error: target must be in ready or failed state."
  exit ${ERROR_BAD_STATE}
fi

UPDATE_START_TIME_S=$(get_time_s)
echo -e "\nPosting update..."
CODE=$(curl -s --connect-timeout ${TIMEOUT_CONNECTION_S} -o /dev/null -w "%{http_code}" -X POST --data-binary @${FILE_PATH} http://${TARGET_IP}:${PORT}/update)
if [[ $? -ne 0 ]]; then
  echo "Error: bad post to target."
  exit ${ERROR_BAD_POST}
fi

if [[ ${CODE} -ne 200 ]]; then
  echo "Error: got error status code (${CODE}) from target."
  exit ${ERROR_BAD_POST}
fi

# Give the target a chance to transition out of the ready/failed state before we
# start checking for a terminal state.  If we started in failed and didn't have
# this we would think we failed below when we didn't even have a chance to get
# out of the failed state.
sleep 1

while true
do
  STATE=$(get_state)

  if [[ ${STATE} == \"rauc_update\" ]]; then
    RAUC_STATE=$(get_rauc_state)    
    echo "Target state: ${STATE}; RAUC state: ${RAUC_STATE}"
  else
    echo "Target state: ${STATE}"
  fi

  if [[ ${STATE} == \"reboot\" ]]; then
    echo -e "\nUpdate successful, this program will wait for the target to reboot."
    echo -e "This could take a bit, ctrl+c to exit now.\n"
    break
  fi

  if [[ ${STATE} == \"failed\" ]]; then
    echo -e "\nUpdate failed with status:"
    curl -s i --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/status
    echo ""
    exit ${ERROR_UPDATE_FAILED}
  fi

  let "TIME_SINCE_START_S = $(get_time_s) - ${UPDATE_START_TIME_S}"
  if [[ ${TIME_SINCE_START_S} -ge ${TIMEOUT_UPDATE_S} ]]; then
    echo "Error: update timed out."
    exit ${ERROR_UPDATE_TIMEOUT}
  fi

  sleep 1
done

REBOOT_START_TIME_S=$(get_time_s)
while true
do
  let "TIME_SINCE_START_S = $(get_time_s) - ${REBOOT_START_TIME_S}"
  let "TIME_REMAINING_S = ${REBOOT_SLEEP_TIME_S} - ${TIME_SINCE_START_S}"

  if [[ ${TIME_REMAINING_S} -le 0 ]]; then
    break
  fi

  echo -e -n "\r\033[KSleeping for ${TIME_REMAINING_S} seconds..."
  sleep 1
done

echo -e "\n"

echo "Attempting to reconnect to target; if using wifi you may need to connect to the access point."
while true
do
  STATE=$(get_state)
  echo "Target state: ${STATE}"

  if [[ ${STATE} == \"ready\" ]]; then
    echo -e "Target back online."
    break
  fi

  let "TIME_SINCE_START_S = $(get_time_s) - ${REBOOT_START_TIME_S}"
  if [[ ${TIME_SINCE_START_S} -ge ${TIMEOUT_REBOOT_S} ]]; then
    echo "Error: reboot timed out."
    exit ${ERROR_REBOOT_TIMEOUT}
  fi

  sleep 2
done

echo -e "Querying version information:"
curl -s i --connect-timeout ${TIMEOUT_CONNECTION_S} -X GET http://${TARGET_IP}:${PORT}/version

echo -e "\n\nWaiting for Boot BIT to run.\n"
BOOTBIT_START_TIME_S=$(get_time_s)
while true
do
  STATE=$(get_boot_state)

  if [[ ${STATE} != \"\" ]]; then
    if [[ ${STATE} == \"healthy\" ]]; then
      echo "Boot BIT is healthy."
      break
    else
      echo "Boot BIT failed with status: ${STATE}"
      exit ${ERROR_BOOTBIT_NOT_HEALTHY}    
    fi
  fi

  let "TIME_SINCE_START_S = $(get_time_s) - ${BOOTBIT_START_TIME_S}"
  if [[ ${TIME_REMAINING_S} -ge TIMEOUT_BOOTBIT_S ]]; then
    echo "Error: timed out waiting for the Boot BIT to complete."
    exit ${ERROR_BOOTBIT_TIMEOUT}
  fi

  sleep 0.5
done

echo -e "\nUpdate complete!"
