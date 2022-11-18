#!/bin/sh
#
# Wrapper script for camera-node
# Checks and updates the time to current time prior to launch

testDate=$(date +%s)
targetDate=1663632004
if [ $testDate -le $targetDate ]
then
  timedatectl set-ntp 0
  sleep 1
  timedatectl set-time 2022-09-20
  sleep 1
fi
node dashcam-api.js
