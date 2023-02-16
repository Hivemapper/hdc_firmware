#!/bin/sh

# This brings down the Wifi AP on wlan0 and brings up wifi direct
# Note you will still need to establish a wpa_cli connection

echo "Stopping services"
systemctl stop wifiP2P
sleep 1
systemctl stop wpa_supplicant
sleep 1
systemctl stop hostapd
sleep 1
systemctl stop dhcpcd
sleep 1
systemctl stop dnsmasq
sleep 1

echo "Copying configurations over"
cp /opt/dashcam/cfg/P2P_dhcpcd.conf /etc/dhcpcd.conf
cp /opt/dashcam/cfg/P2P_dnsmasq.conf /etc/dnsmasq.conf

echo "Restarting network services"
systemctl restart wpa_supplicant
sleep 1
systemctl restart systemd-networkd
sleep 1
systemctl restart dhcpcd
sleep 1
systemctl restart dnsmasq
sleep 1
systemctl restart wifiP2P

echo "Updaing network mode file"
rm /opt/dashcam/network-mode.txt
echo "P2P" > /opt/dashcam/network-mode.txt
