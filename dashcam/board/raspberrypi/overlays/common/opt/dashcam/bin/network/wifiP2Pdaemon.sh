#!/bin/sh
#
# wifiP2Pdaemon.sh
#
# This is the wifi-p2p daemon script.
# 
#
# Copyright 2023 Hellbender Inc.
# All Rights Reserved
#
# Changelog:
# Author Email, Date,     , Comment
# niessl      , 2023-02-15, Created File
#

# 
# It does the following:
#
# 1. Check if the wifi.cfg file exists, is in P2P, and has a target host.
#    Abort with unusual exit code if this is not the case.
# 2. Delete any existing wifi p2p groups if detected. Then procede to
#    set up the wifi p2p interface.
# 3. Initiate the wifi-direct handshake. If the handshake fails, this
#    will abort with unusual exit code.


found_result=0
device_name=""

# STEP 1: Check for wifi.cfg parameters.

if [ ! -e "/mnt/data/wifi.cfg" ]
then
  echo "ERROR: No wifi config file found, aborting."
  exit 1
else
  device_name=`awk -F "\"*, \"*" '{print $2}' /mnt/data/wifi.cfg`
fi

if [ $device_name = "" ]
then
  echo "ERROR: Attempting to run P2P when no device name provided, aborting."
  exit 2
fi

echo "Will attempt connection with $device_name"

# STEP 2: Delete old connections, and start up p2p find.

if [ -e "/tmp/CONNECT_SUCCESS" ]
then
  rm /tmp/CONNECT_SUCCESS
fi

if [ -e "/tmp/CONNECT_FAIL" ]
then
  rm /tmp/CONNECT_FAIL
fi

wpa_cli -i wlan0 p2p_flush
sleep 1
wpa_cli -i wlan0 set config_methods
sleep 1

interface=$(ip link | grep -E -o 'p2p-wlan0-[0-9]+')
if [ ! interface="" ]
then
  wpa_cli -i wlan0 p2p_group_remove $interface
  sleep 1
fi

wpa_cli -i wlan0 set config_methods virtual_push_button
sleep 1
wpa_cli -i wlan0 p2p_find
sleep 1

# STEP 3: Connect and handshake

connected=0

for CHECK in 1 2 3 4 5 6 7 8 9 10
do
  mac_to_connect=""
  probe_result=$(wpa_cli -i wlan0 p2p_peers) 
  echo "Finding a match..."
  for macaddr in $probe_result
  do
    command="wpa_cli -i wlan0 p2p_peer $macaddr"
    echo "Filtering on command: $command"
    devIDLine=$(wpa_cli -i wlan0 p2p_peer $macaddr | grep -E "device_name=$device_name")
    if [ -n "$devIDLine" ]
    then
      echo "Match found: $devIDLine"
      found_result=1
      mac_to_connect=$macaddr
      break
    fi
  done
  if [ $found_result -eq 1 ]
  then
    break
  fi
  echo "No match found. Waiting and retrying"
  sleep 3
done

if [ $found_result -eq 0 ]
then
  echo "No match. Retry "
else
  for CHECK in 1 2 3 4 5
  do
    connect_result=$(wpa_cli -i wlan0 p2p_connect $mac_to_connect pbc)
    if [ $connect_result == "FAIL" ]
    then
      echo "Failed to connect to $mac_to_connect. Retrying..."
    else
      echo "Success! Connecting to $mac_to_connect"
      wpa_cli -i wlan0 p2p_connect $mac_to_connect pbc
      connected=1
      break
    fi
    #Increase delay to six seconds, this seems to be the touchy part
    sleep 6
  done
fi

if [ $connected -eq 1 ]
then  
  echo "Connected to $device_name"
  touch /tmp/CONNECT_SUCCESS
  exit 0
else
  echo "Failed to find a connection"
  touch /tmp/CONNECT_FAIL
  #Redo the deletion on fail
  wpa_cli -i wlan0 p2p_flush
  sleep 1
  wpa_cli -i wlan0 set config_methods
  sleep 1
  if [ ! interface="" ]
  then
    wpa_cli -i wlan0 p2p_group_remove $interface
    sleep 1
  fi
  exit 3
fi

