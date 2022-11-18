#!/bin/sh

# Debug/test functionality to make sure all associated
# services can go down and back up.

ResultFile="/mnt/data/wifi_results.txt"

touch $ResultFile 
echo "Switching to P2P" >> $ResultFile
sh /opt/dashcam/bin/network/wifi_switch_P2P.sh >> $ResultFile
sleep 15
echo "Switching back" >> $ResultFile
sh /opt/dashcam/bin/network/wifi_switch_AP.sh >> $ResultFile
