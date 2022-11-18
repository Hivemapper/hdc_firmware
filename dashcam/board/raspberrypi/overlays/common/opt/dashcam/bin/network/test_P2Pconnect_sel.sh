#!/bin/sh

# Debug/test functionality to make sure all associated
# services can go down and back up.

resultFile="/mnt/data/wifi_results.txt"

if [ -z "$1" ]
then
  echo "You need to provide a Device Name to connect to!"
  exit -1
fi

if [ -f "/tmp/CONNECT_SUCCESS" ]
then
  rm /tmp/CONNECT_SUCCESS
fi
if [ -f "/tmp/CONNECT_FAIL" ]
then
  rm /tmp/CONNECT_FAIL
fi

touch $resultFile
echo "Switching to P2P" >> $resultFile
sh /opt/dashcam/bin/network/wifi_switch_P2P.sh >> $resultFile
sleep 5
echo "Looking for phone with device_id $1" >> $resultFile
sh /opt/dashcam/bin/network/wifi_P2Pconnect_sel.sh $1 >> $resultFile
sleep 5
if [ -f "/tmp/CONNECT_SUCCESS" ]
then
  echo "Success!" >> $resultFile
else
  echo "Failed! Switching back" >> $resultFile
  sh /opt/dashcam/bin/network/wifi_switch_AP.sh >> $resultFile
fi

