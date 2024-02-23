#!/bin/bash

if [ ! -d "/tmp/recording/preview" ]
then
  mkdir /tmp/recording/preview
fi

if [ ! -d "/tmp/recording/pic" ]
then
  mkdir /tmp/recording/pic
fi

if [ ! -d "/mnt/data/pic" ]
then
  mkdir /mnt/data/pic
fi

if [ ! -d "/mnt/data/pic_lg" ]
then
  mkdir /mnt/data/pic_lg
fi

output=$(df | grep "media")
if [ -n "$output" ];
then
  if [ ! -d "/media/usb0/recording" ]
  then
    mkdir /media/usb0/recording
  fi
fi

nice -n -1 ionice -c 1 -n 0 -t ./libcamera-bridge --config camera_bridge_config.json --config-override /mnt/data/camera_bridge_config.json --segment 0  --timeout 0 --tuning-file imx477.json
