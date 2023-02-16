#!/bin/sh
#
# Set the hostname on start based on the serial number.

set -euo pipefail

# To get serial number, on 32-bit we can use the vcgencmd, but that package isn't
# part of the 64-bit build.  So, we can actually get the serial number out of
# /proc/cpuinfo.  But I'm going to leave the vcgencmd method here as a future
# reference...

# Field 28 of the One Time Programmable memory is serial number.
# https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#otp-register-and-bit-definitions
# SN=$(vcgencmd otp_dump | grep 28: | awk -F":" '{print $2}')

# There is a prepend of 10000000 in front of the S/N we care about.
LONGSN=$(cat /proc/cpuinfo | grep Serial | xargs | awk -F: '{print $2}')
SN=${LONGSN:9}

HOSTNAME="dashcam-${SN}"

# Set in 3 places.  You would think /etc/hostname would drive what is used
# by the "hostname" command but no, they are decoupled.
# 2023-02-01 CTN: Now 4 places with wi-fi direct. Add in wpa_supplicant.conf
echo "${HOSTNAME}" > /etc/hostname
sed -i "s/dashcam/${HOSTNAME}/g" /etc/hosts
sed -i "s/DIRECT-dashcam/DIRECT-${HOSTNAME}/g" /etc/wpa_supplicant.conf
hostname ${HOSTNAME}

# Finally, make the SSID unique in case we have multiple dashcams in the same
# area.  This script should be running before the hostapd service starts.
sed -i "s/ssid=dashcam/ssid=${HOSTNAME}/g" /etc/hostapd.conf
