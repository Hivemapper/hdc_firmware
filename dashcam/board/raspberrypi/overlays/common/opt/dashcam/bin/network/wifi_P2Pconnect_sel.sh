#!/bin/sh

# This connects to the device whose MAC Address is provided
# to the script. If none is provided, it exists.

found_result=0

if [ -z "$1" ]
then
  echo "You need to provide a Device Name to connect to!"
fi

wpa_cli -i wlan0 set config_methods virtual_push_button
wpa_cli -i wlan0 p2p_find

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
    devIDLine=$(wpa_cli -i wlan0 p2p_peer $macaddr | grep -E "device_name=$1")
    if [ -n "$devIDLine" ]
    then
      echo "Match found"
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
    sleep 3
  done
fi

if [ $connected -eq 1 ]
then  
  echo "Connected to $con_addr"
  touch /tmp/CONNECT_SUCCESS
else
  echo "Failed to find a connection"
  touch /tmp/CONNECT_FAIL
fi

