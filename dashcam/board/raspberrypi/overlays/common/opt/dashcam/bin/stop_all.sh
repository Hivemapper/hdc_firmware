#!/bin/sh
#
# Stop all processes running on the camera.
# Includes all processes that could talk to the eMMC

systemctl stop camera-node
systemctl stop camera-bridge
systemctl stop camera-bridge.timer
systemctl stop gnss-logger
systemctl stop imu-logger
systemctl stop lorawan-logger
systemctl stop led-controller
systemctl stop rauc
systemctl stop onboard-updater
