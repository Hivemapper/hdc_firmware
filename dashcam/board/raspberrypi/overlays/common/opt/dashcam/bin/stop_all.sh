#!/bin/sh
#
# Stop all processes running on the camera.
# Includes all processes that could talk to the eMMC

systemctl stop camera-node
systemctl stop api-health-manager
systemctl stop camera-bridge
systemctl stop data-logger
systemctl stop lorawan-logger
systemctl stop led-controller
systemctl stop rauc
