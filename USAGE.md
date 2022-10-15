# Utilites

For all these programs, full options can be found with --help.
The most likely to be changed options are listed here.

## imu-logger

--live Output samples to stdout, does not disable logging to file.
--logInterval Interval duration, in milliseconds, data collection.
--logDuration Duration of each log file in seconds.

## gnss-logger

--snr Ouptut snr to log
--minMode Minimum fix mode to log

## lorawan-logger

--live Output message responses to stdout.
--verbose 0 quiet, 1 error (default), 2 warn, 3 info, 4 debug (outputs things like rssi and radio configurations) These messages are logged to stderr.
--input-path directory to watch for commands, defaults to /tmp/lorawan
--output-path directory to write responses to, defaults to /tmp/lorawan, though the systemd service sets it to /mnt/data/lorawan

## eeprom access and serial information

--eeprom_access.sh is used to read/write information from the EEPROM
--The first 32 bytes of each EEPROM bank is dedicated to serial-number/board revision information.
--To access the first 32 bytes for read/write, you must use the -s argument.
--For example, to program the contents for a file into the EEPROM serial space:
  sh eeprom_access.sh -w -f serialInfo.bin -o 0 -ba 0 -s
--Example to read the Serial space data into a file
  sh eeprom_access.sh -r -f /tmp/dump.bin -o 0 -ba -s
  cat /tmp/dump.bin
  52197cfa+B1C0HWXX___+TESTSIL___
--Serial information is formatted as followed:
  8 Bytes SSID, '+', 11 Bytes Board config, '+', 10 Bytes Hellbender Serial
  
# Scripts

## resize-data-partition.sh

No options, this script resizes the data (/dev/mmcblk0p4) partition and filesystem to fill the emmc. Find the script at:
/opt/dashcam/bin/resize-data-partition.sh

## Access point and wifi-direct scripts

The /opt/dashcam/bin/network directory has ten different scripts useful for managing what type of network endpoint is available.

### Basic switching utilities

1. wifi\_switch\_AP.sh - Bring up the Access point configuration.

1. wifi\_switch\_P2P.sh - Bring up the P2P (Wi-fi direct) configuration.

1. wifi\_P2Pconnect\_any.sh - Attempt a P2P handshake with any device available. Only works when P2P interface is up.
Generated /tmp/CONNECT\_SUCCESS on success or /tmp/CONNECT\_FAILURE on failure.

1. wifi\_P2Pconnect\_sel.sh *DEVICENAME* - Attempt a P2P handshake with the device matching *DEVICENAME*. Only works when P2P interface is up.
Generated /tmp/CONNECT\_SUCCESS on success or /tmp/CONNECT\_FAILURE on failure.

1. wifi_P2Prmgroup.sh - Remove the current P2P state and group information. Necessary if the device disconnected before attempting a reconnection.
This brings the device into the same networking state as though you ran wifi\_switch\_P2P.sh after being in AP mode.

### Advanced tests and scripts

All of these scripts invoke the previous four, so if you modify any of those, take care to update these!

1. test\_WifiSwitch.sh - Tests switching from AP mode, to P2P mode. Lingers in P2P mode for 15 seconds, then switches back to AP mode.
Useful for checking if interfaces are configured properly.

1. test\_P2Pconnect\_any.sh - Brings down the default AP configuration and brings up the P2P, while initiating a handshake with
any available device. Gives a grace period of 1 minute, where if a connection is not detected by then, it switches back to AP mode.
It does this by checking the CONNECT\_SUCCESS/CONNECT\_FAILURE files generated by wifi\_P2Pconnect\_any.sh

1. test\_P2Pconnect\_sel.sh *DEVICENAME* - Brings down the default AP configuration and brings up the P2P, while initiating a handshake with
the device matching *DEVICENAME*. Gives a grace period of 1 minute, where if a connection is not detected by then, it switches back to AP mode.
It does this by checking the CONNECT\_SUCCESS/CONNECT\_FAILURE files generated by wifi\_P2Pconnect\_sel.sh

1. test\_P2Preconnect\_any.sh - Brings down the P2P group information, and then reinitiates a handshake with a new group to any available device.
Gives a grace period of 1 minute, where if a connection is not detected by then, it switches back to AP mode.
Checks the same CONNECT\_SUCCESS/CONNECT\_FAILURE files as wifi\_P2Pconnect\_any.sh

1. test\_P2Preconnect\_sel.sh - Brings down the P2P group information, and then reinitiates a handshake with the device matching *DEVICENAME*
Gives a grace period of 1 minute, where if a connection is not detected by then, it switches back to AP mode.
Checks the same CONNECT\_SUCCESS/CONNECT\_FAILURE files as wifi\_P2Pconnect\_sel.sh

## Live preview of video

systemctl start camera-preview

The preview parameter is defined in config.json and defaults to /tmp/recording/pic. If for whatever reason you need to change it, you can do that
there. However, if you do change it, you must also change preview.sh, since that is the wrapper script for mjpg_streamer.

To view the video, you can access http://192.168.0.10:9001/?action=stream

TODO: Jitter from the main feed writing to disk can make the video choppy. 
Redirecting the normal image stream to /tmp/recording during a preview session may mitigate this.

## 2nd drive recording and waiting for GNSS Lock

config.json contains configuration parameters for the 2nd recording location.

"output2" - Location of where else to record frames. By default this is "/media/usb0/recording/"
"minfreespace2" - Minimum free space to leave on the 2nd location. By default this is 32000000
"gpsLockCheckDir" - Where to check for the GPS to be ready. If unspecified, it doesn't look and records images in the 2nd location immediately. 
The default location of gnss to write its ready file is "/tmp/GPS_READY" So gpsLockCheckDir should be set to that if gnss-logger configuration is unchanged.