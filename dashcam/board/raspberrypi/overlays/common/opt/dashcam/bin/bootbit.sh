#!/bin/sh
#
# Built-in-test that runs on boot to verify a boot is good and to handle
# success and failure.
#
# A note on time: I'm distrustful of using the system clock since this is a target
# that does not have accurate time and may have a clock jump if NTP sync kicks in.
# So I'm going to use loops with a number of iterations and 1 second sleeps, so 
# the number of iterations approximates amount of time the loop may run.
# 
# Print echoes get written to systemd/journald.  View using either:
# journalctl [OPTIONS]
# systemctl status bootbit
# Additionally, errors get routed to the kernel log (i.e. dmesg).

# Right now the 64-bit build doesn't build the camera-api package (i.e.
# capable_camera_firmware).  So make it possible to ignore that in the BIT.
IGNORE_CCF=1

# Start by figuring out if this is the first boot after an update.
NEW_UPDATE=$(fw_printenv UNBOOTED_UPDATE | awk -F= '{print $2}') 
[ "$?" -ne 0 ] && NEW_UPDATE=1

# After this (either success or failure) it will not be the first boot after an
# update.  Even if it fails and we revert to the inactive slot.
fw_setenv UNBOOTED_UPDATE 0

# We should probably pull the expected address from dhcpcd.conf.
WIFI_IP=192.168.0.10
OU_PORT=5000

print_info() {
  echo -e "$1" | systemd-cat -p info -t bootbit
}

print_error() {
  echo -e "$1" > /dev/kmsg
  echo -e "$1" | systemd-cat -p emerg -t bootbit
}

fail() {
  print_error "BIT failed: $1"

  if [ ${NEW_UPDATE} -ne 0 ]; then
    # If we fail on the first boot after an update we immediately revert to the
    # previous slot.
    rauc status mark-bad
    # Give a polling client long enough to read the OU bootstate before we reboot.
    sleep 1
    reboot
  else
    # If it's not the first boot after an update we are much more pacific.
    # We still mark this slot as good since failure to do so would just mean
    # that the counter would decrement, and after three boots like this the
    # firmware would revert to the inactive slot.  Which would be a surprise to
    # the user.  Basically to be here would mean that the BIT passed after the
    # update but has failed on some subsequent boot, which implies a hardware
    # failure, not a software or configuration failure.  And if it is hardware,
    # then switching to the inactive slot won't help anyways.
    rauc status mark-good
    exit 1
  fi
}

# Gets a process ID given a greppable string.
get_proc_id() {
  local PID
  # The Busybox version of ps is pretty limited and we don't have pgrep.  The args
  # column is the richest and gives the full path of the process.  But that isn't
  # great because we'll also have the "grep" command show up in the result.  So
  # used the "comm" column but beware since that truncates the process name if
  # it is too long.
  PID=$(ps -o pid,comm | grep "$1" | awk '{print $1}')
  echo "${PID}"
}

# Checks process IDs for equivalence and reboots if they don't match.
check_proc_ids() {
  [ "$1" != "$2" ] && fail "$3 PIDs do not match; $1, $2"
}

# Note we're going to search for these using the "comm" column of ps which
# truncates the process name to 15 chars.
OU_PROC="dashcam-api"
RAUC_PROC="rauc"
CCF_PROC="capable_camera_"

OU_PID=
RAUC_PID=
CCF_PID=

# This first loop tries to identify the PIDs of processes we are interested in.
ITER=0
NUM_ITERS=30
while true; do
  [ -z "${OU_PID}" ] && OU_PID=$(get_proc_id "${OU_PROC}")
  [ -z "${RAUC_PID}" ] && RAUC_PID=$(get_proc_id "${RAUC_PROC}")
  [ -z "${CCF_PID}" ] && CCF_PID=$(get_proc_id "${CCF_PROC}")
  
  if [ -n "${OU_PID}" ] &&
    [ -n "${RAUC_PID}" ]
  then
    if [ -n "${CCF_PID}" ] || [ "${IGNORE_CCF}" -ne 0 ]; then
      # If we've found all the processes we're looking for we can kick out early.
      break
    fi
  fi

  ITER=$((ITER + 1))

  [ ${ITER} -ge ${NUM_ITERS} ] && fail "unable to find all processes"

  sleep 1
done

# Now we allow some settling time so that when we wake up we can check the PIDs
# again to make sure the processes haven't crashed and restarted.
sleep 5

NEW_OU_PID=$(get_proc_id "${OU_PROC}")
NEW_RAUC_PID=$(get_proc_id "${RAUC_PROC}")
NEW_CCF_PID=$(get_proc_id "${CCF_PROC}")

check_proc_ids "${OU_PID}" "${NEW_OU_PID}" "${OU_PROC}"
check_proc_ids "${RAUC_PID}" "${NEW_RAUC_PID}" "${RAUC_PROC}"
if [ "${IGNORE_CCF}" -eq 0 ]; then
  check_proc_ids "${CCF_PID}" "${NEW_CCF_PID}" "${CCF_PROC}"
fi

# The wlan0 interface is the last thing to come up.  So we'll give it a bit more time.
# 2023-02-01 CTN: Commented out this whole check. 
# Reasons: 
# 1. IP Addresses
# 2. WiFi is checked on a software build before deployment on SIL, if it doesn't pass
#    we avoid distributing it and the SIL can be reflashed easily on fails.
# 3. This only helps recover a software-based wifi issue. Hardware issues would not
#    be recoverable with this system.

#ITER=0
#NUM_ITERS=10
#while true; do
  # There may be a better way of testing this but this seems sufficient.  If hostapd
  # didn't bring up the interface it won't have an IP address on wlan0.
#  ip addr show wlan0 | grep ${WIFI_IP} > /dev/null 2>&1
#  [ "$?" -eq 0 ] && break

#  ITER=$((ITER + 1))

#  [ ${ITER} -ge ${NUM_ITERS} ] && fail "wlan0 is not up with expected IP address"

#  sleep 1
#done

# Test ODC API is answering requests
wget http://localhost:${OU_PORT}/api/1/info --spider > /dev/null 2>&1
[ "$?" -ne 0 ] && fail "cannot get status from ODC API"

# Test that the persistent data partition is mounted.
cat /proc/mounts | grep /mnt/data > /dev/null 2>&1
[ "$?" -ne 0 ] && fail "data partition not mounted"

# This resets the boot counter for this slot group.
rauc status mark-good
touch /opt/dashcam/READY
echo "BOOT TEST PASSES"

# Configure cpu to boost
echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
