#!/bin/sh
#
# wifiman.sh
#
# This is the wifi manager script
# 
#
# Copyright 2023 Hellbender Inc.
# All Rights Reserved
#
# Changelog:
# Author Email, Date,     , Comment
# niessl      , 2023-02-13, Created File
#

# 
# This checks the wifi.cfg script and selects the
# appropriate configurations for either AP or P2P
# mode, and disables systemd processes for the 
# un-used method.
#

wifi_mode="UNKNOWN"
device_name="UNKNOWN"

if [ ! -e "/mnt/data/wifi.cfg" ]
then
  wifi_mode="AP"
  echo "AP, " > /mnt/data/wifi.cfg
  echo "No file found, setting up"
else
  wifi_mode=`awk -F "\"*, \"*" '{print $1}' /mnt/data/wifi.cfg`
  device_name=`awk -F "\"*, \"*" '{print $2}' /mnt/data/wifi.cfg`
  echo "Using $wifi_mode, with device $device_name"
fi

if [ $wifi_mode = "AP" ]
then
  echo "Using Access Point mode"
  cp /opt/dashcam/cfg/AP_dhcpcd.conf /etc/dhcpcd.conf
  cp /opt/dashcam/cfg/AP_dnsmasq.conf /etc/dnsmasq.conf
  systemctl disable --now wpa_supplicant
  systemctl disable --now wifiP2P
elif [ $wifi_mode = "P2P" ]
then
  echo "Using P2P Direct mode"
  cp /opt/dashcam/cfg/P2P_dhcpcd.conf /etc/dhcpcd.conf
  cp /opt/dashcam/cfg/P2P_dnsmasq.conf /etc/dnsmasq.conf
  systemctl disable --now hostapd
else
  echo "No service found, something went wrong."
  echo "Reverting to AP"
  cp /opt/dashcam/cfg/AP_dhcpcd.conf /etc/dhcpcd.conf
  cp /opt/dashcam/cfg/AP_dnsmasq.conf /etc/dnsmasq.conf
  systemctl disable --now wpa_supplicant
  systemctl disable --now wifiP2P
  echo "AP, " > /mnt/data/wifi.cfg
  sync    
fi

echo "Manager setup finished"
