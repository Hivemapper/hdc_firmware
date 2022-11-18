#!/bin/sh

# This brings down any wifi-direct configuration and brings up
# the original Access point configuration.

echo "Stopping services"
killall -9 wpa_supplicant
sleep 1
systemctl stop hostapd
sleep 1
systemctl stop dhcpcd
sleep 1
systemctl stop dnsmasq
sleep 1

echo "Copying configurations over"
cp /opt/dashcam/cfg/AP_dhcpcd.conf /etc/dhcpcd.conf
cp /opt/dashcam/cfg/AP_dnsmasq.conf /etc/dnsmasq.conf

echo "Restarting network services"
systemctl restart systemd-networkd
sleep 1
systemctl restart hostapd
sleep 1
systemctl restart dhcpcd
sleep 1
systemctl restart dnsmasq
sleep 1

echo "Updaing network mode file"
rm /opt/dashcam/network-mode.txt
echo "AP" > /opt/dashcam/network-mode.txt
