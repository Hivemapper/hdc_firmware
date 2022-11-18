# dashcam

## Prerequisites

The `dashcam` project uses the `onboardupdater` package, which is currently kept in the Hellbender
BitBucket.  You need to have SSH keys setup so that Buildroot can download the git repo.

## Dependencies
Refer to (or run) the [scripts/host_setup.sh](./scripts/host_setup.sh) for a list of required
and optional dependencies.

Alternatively, refer to the Buildroot manual for 
[required and optional dependencies](https://buildroot.org/downloads/manual/manual.html#requirement).

To add to that:

### Required
* `git`

### Optional
* `cmake` - Although Buildroot will build cmake if necessary it optimizes by using the CMake
on the host system if the version is recent enough.  Using the host CMake can save 5+ minutes
in rebuild time.

* `qt5` - This is packaged as `qt5-default` on Ubuntu 20.  This allows bringing up a better UI
interface when running `make xconfig`.

* `curl` - Necessary to use the `update_http.sh` script.

* `jq` - Necessary to use the `flash_resize_image.sh` and `update_http.sh` scripts.

## Getting Started

1. Clone the top-level dashcam repository with submodules.  The repository is hosted on BitBucket
so make sure you have SSH keys setup (this is a requirement of this project).

    ```
    git clone --recurse-submodules git@bitbucket.org:chr1sniessl/dashcam.git
    cd dashcam
    ``` 

2. Setup a target build.  The config files are setup to build both 32-bit and 64-bit images,
though the camera SW only supports 32-bit at the moment so that is preferred.  We also distinguish
between production and development builds.  See section below, but
`raspberrypicm4io_dev_dashcam_defconfig` should be considered the default option for developers
and `raspberrypicm4io_prod_dashcam_defconfig` for production use.
    ```
    make -C buildroot/ BR2_EXTERNAL=../dashcam O=../output raspberrypicm4io_64_dev_dashcam_defconfig
    ```

3. Perform the build.  With no ccache a rebuild should take about 30-40 minutes.
    ```
    cd output
    make
    ```

4. Install the image on the target using your preferred method.  `images/sdcard.img` is a full disk 
image suitable for flashing.  For the CM4IO target, to flash you need the pin jumper and a 
connection to the target's USB flashing port.  The commands to install the bootloader,
flash the device, and resize the final data partition have all been collected into a
script.  Relative to the `output` directory and assuming the device will mount to `/dev/sda`, run:
    ```
    ../scripts/flash_resize_image.sh sda
    ```
    This script has basic safety checks that the target is connected to the given device (e.g. `sda`),
    and is in fact a Raspberry Pi!
    
5. After flashing the full disk image, changes to the image can use over-the-air updates.  

    **The preferred method** for doing updates is the production method using the
    onboard updater over http.  A script is provided to perform the update from the host.
    Relative to the `output` directory and assuming a target IP address, run:
    ```
    ../scripts/update_http.sh 192.168.1.10
    ```
    You should see the update progress in the console and the target will reboot.  When it comes
    up again it will display the version info of the new image.

    During development, we also support a mode that leaves SSH open to a root user with no
    password.  A script is also provided for this method:
    ```
    ../scripts/update_ssh.sh 192.168.1.10
    ```

Do note that steps 2 and 3 can be performed using the [scripts/rebuild.sh](./scripts/rebuild.sh) script.

## USB Updates

### Process
USB updates were added as of 08/23/2022.  To do a USB update, do the following: 

1. Acquire a USB flash drive that's formatted with a FAT32 root file system.
1. Add a directory named "hivemapper_update" to the root of the flash drive.
1. Add the rauc bundle (*.raucb) to the previously made directory.
    1. The naming of the update doesn't matter.  The update routine will look 
    specifically for the .raucb extension.
    1. Only place one file ending with the extension .raucb in the update directory.
    1. If the storage of multiple .raucb files is desired, add an additional extension to
    the unused files, i.e. ".old" or ".other".  This will allow the update infrastructure
    to find the appropriate update file.
1. Connect the flash drive to the hardware.
1. Power cycle the device.
1. Wait a couple minutes to ensure the updates have been completed.  In this time period
the LED's should turn off then back on a couple times.

### Inter-workings
Below is the processes that's completed when doing a USB update:

1. On startup, systemd starts a script to do the update
1. The script looks in all the USB mount points for a directory called "hivemapper_update".
1. If the script finds the directory, it looks in the directory for a single
update bundle (.raucb) file.
1. If one update bundle was found, the script updates the system time based on the
start date of the update certificate.  It then gets the checksum for the current
root file system and the update bundle.
1. If the checksums don't match, the script will move the update file to the
/tmp directory and call "rauc install" on it
1. If the install succeeds, the system is rebooted.

NOTE: If any of the steps above fails, an error will be output and the update process with exit


## Working With the Target

### Getting a Console
Right now all builds are in development mode, which provides a root user with no password.  You can 
get a console to the target using one of the following:
1. Use the virtual terminal.  We run a getty session on TTY1.  Just connect an HDMI monitor and USB 
keyboard.
2. Use the GPIO pins.  We run a serial console on UART0 and you can use a USB-to-GPIO cable as 
discussed [here](https://elinux.org/RPi_Serial_Connection).  You can see the CM4IO pinout 
[here](https://pi4j.com/1.3/pins/rpi-cm4.html), of which you use pins 6,8,10.
3. Use SSH.  You can connect using the root user with no password.

### Networking
The target uses both wired ethernet and wifi interfaces.
* On the wired ethernet interface the target is a DHCP client.  The target gets an IP address on the wired 
ethernet adapter from the an external DHCP server (which you have to provide if one isn't already on the LAN).
* On the wifi interface the target is an access point.  It sets a static IP address of `192.168.0.10` 
for itself and runs a DHCP server that assigns addresses in the `192.168.0.[11-50]` range.  The
wifi SSID is `dashcam` and the password is `hivemapper`.

## Build Configurations
Build configuration is driven purely by the `_defconfig` chosen when using the `make` command.
The options are:
* raspberrypicm4io_prod_dashcam_defconfig
* raspberrypicm4io_dev_dashcam_defconfig
* raspberrypicm4io_64_prod_dashcam_defconfig
* raspberrypicm4io_64_dev_dashcam_defconfig

### Production vs Development
Development mode enables some extra features in the O/S:
* A root login with no password.
* SSH access (again with a root user and no password).
* A virtual terminal.
* A serial console on UART0.

When switching between production and development modes it is highly recommended you execute a
`make clean` in order to force a full rebuild.

## Troubleshooting

### How Do I Find The Target's IP Address?
If you connect to the target using wifi see the Networking section for the target's static IP address.

If you connect using the wired ethernet interface then the target will have an IP address assigned
by the LAN's DHCP server.  If you have a console session on the target, then you 
can run `ip addr`.  If you don't have a working console, you can search for the target on your 
subnet using `arp-scan`.  For example, on a `192.168.1.xxx` subnet LAN:
```
sudo arp-scan 192.168.1.0/24
```
The target will likely show up as `(Unknown)`.

### My USB Keyboard Doesn't Work in the Virtual Console
Make sure you've unplugged the USB cable from the USB flashing port.  That seems to messup the use 
of a USB keyboard.

### The USB Thumb Drive Isn't Being Mounted
As with other USB problems, make sure you've unplugged the USB cable from the USB flashing port.

### Remote Host Identification Error
If you are using SSH to the target (like when using the `update_ssh.sh` script) you may get an
error that starts:
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```
This is because the SSH keys have changed on the target and to your host the target at the IP
address looks like it has changed.  SSH keys for the target are generated on a full rebuild,
so that's likely why they have changed.

The error message has the solution: run the `ssh-keygen` command with the `-R` option.  For me:
```
ssh-keygen -f "/home/cshaw/.ssh/known_hosts" -R "192.168.1.10"
```

You can also ease ssh access with these two configuration options in .ssh/config:

```
Host 192.168.0.10
    user root
    StrictHostKeyChecking no

```
Bear in mind that these options will apply to any host 192.168.0.10, not just the dashcam.


### Flashing the Target is Stuck "Waiting for BCM2835/6/7/2711..."
This is the RPi bootloader.  Do the following:
1. Ensure the pin jumper is installed.
2. Ensure the USB-C flashing cable is attached.
3. Power cycle the target.

## Developing in the Dashcam Project

### Updating the Capable Robot Camera Software
1. Changes are pulled in from the Capable Robot repo, so changes in the camera software first need to 
be pushed to the camera repo GitHub.  The change itself doesn't need to be in the main branch,
it just needs a hash.

2. The hash needs to be modified in the [camera-cpp.mk](./dashcam/package/camera-cpp/camera-cpp.mk)
file and the [camera-zig.mk](./dashcam/package/camera-zig/camera-zig.mk) files.  Since the camera
SW has two different build systems in the same tree we build it as two separate projects but

3. From the `output` directory, run `make`.

### Updating the RPi `config.txt` file.
`config.txt` for each target is modified from the default.  For example, you can find one target
version [here](./dashcam/board/raspberrypi/config_cm4io.txt).  If you modify that, then from
the `output` directory:
```
rm -rf build/rpi-firmware*
make
# After the build finishes you can confirm your changes by:
cat images/rpi-firmware/config.txt
```

### Producing a Production Build

On top of making sure to use a production default configuration (see above), do make sure to
roll the semantic version in the [post-build.sh](./dashcam/board/raspberrypi/post_build.sh)
script.

### Making Buildroot Configuration Changes

Running `make` to build a Buildroot project uses the `output/.config` file to fully specify the
Buildroot configuration.  This file is not under source control and is out-of-sight, out-of-mind,
so it is another source of confusion when it looks like changes you've made are not being applied.

The `output/.config` file is set when:
1. You make a default config, such as `make raspberrypicm4io_dev_dashcam_defconfig`.  Buildroot
applies the defconfig to the Buildroot defaults to generate the `output/.config` file.
2. You run the menu editor (e.g. `make xconfig`) and save changes.

**Changes to `output/.config` are not automatically transferred back to the defconfig that is under
git source control.**  To do that you need to `make savedefconfig`.  This will only apply then changes
to the defconfig that the `output/.config` file was generated from.  Since there are multiple
defconfigs in the dashcam project you should probably also manually copy the defconfig changes to
other defconfig files.

Keeping the defconfig in sync with the `output/.config` file is an important part of minimizing
Buildroot "weirdness".

## Updating the Firmware

The dashcam provides an HTTP server to manage firmware updates.
[Refer to the Onboard Updater project](https://github.com/cshaw9-rtr/onboardupdater) for a
description of the API.  Or use the update script [provided in this project here](./scripts/update_http.sh).

## Docker

A Dockerfile is provided in the project root and can be used to build update artifacts in an
environment isolated from the host system, and perhaps in the future, using a CI build server.
To use:

1. Setup your host system to use Docker based on [Docker instructions here](https://docs.docker.com/engine/install/ubuntu/).

2. Build the Docker image.  Do this the first time, and anytime the dashcam source code changes.
    From the project root:
    ```
    docker build --rm -t dashcam .
    ```
    This will produce the `dashcam:latest` image, as verified using `docker image ls`.

3. Run a container based on the image.
    ```
    docker run --rm -it dashcam
    ```
    This will start a bash shell in the container in the project root.  The source code files in the
    container are copies of those on the host system when the Docker image was built, so once again,
    **if the source code changes, repeat step #2**.

4. Do a rebuild.
    ```
    ./scripts/rebuild.sh
    ```
    Where options passed to the rebuild script specify the build configuration.

5. Optionally copy the build artifacts out of the container using any number of methods, such as
    [those described here](https://stackoverflow.com/questions/22049212/docker-copying-files-from-docker-container-to-host).

6. Optionally update the target using [scripts/update_http.sh](./scripts/update_http.sh).

### Future

If the use of Docker becomes part of the workflow:
* The use of ENTRYPOINT/CMD could be used to kick off a build automatically without need for an
interactive bash session.
* The copying of the build artifacts back to the host could be automated.

## Limitations

### 64-bit

While there is a configuration for 64-bit (aarch64), it is not fully supported right now due to
the fact that the Zig component of the camera software does not build with a 64-bit toolchain.
