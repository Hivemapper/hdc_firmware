#!/bin/sh

# Variables to be used in script
MOUNT_PATH="/media"
START_INDEX=0
END_INDEX=7
MOUNT_DIR_PREFIX="usb"
UPDATE_DIR="hivemapper_update"
CERT_PATH="/etc/rauc/keyring/cert.pem"
SCRIPT_PATH="/opt/dashcam/bin"

# Loop thought all usb mount points
for INDEX in $(seq $START_INDEX $END_INDEX); do
    # Prepare to search for files
    BASE_DIR="$MOUNT_PATH/$MOUNT_DIR_PREFIX$INDEX"
    SEARCH_PATH="$BASE_DIR/$UPDATE_DIR"
    echo "Searching for update direcory in \"$BASE_DIR\""
    echo $SEARCH_PATH
    if [ -d $SEARCH_PATH ]; then
        echo "Found update directory! Looking for update file..."

        # Validate there isn't more than one update bundle
        UPDATE_FILE_SEARCH=$(ls -1 $SEARCH_PATH/*.raucb)
        UPDATE_FILE_COUNT=$(echo $UPDATE_FILE_SEARCH | wc -l)
        if [ $UPDATE_FILE_COUNT -eq 1 ]; then
            echo "Found one update file."

            # Get date from update certificate
            echo "Getting cert date"
            CERT_DATE=$(openssl x509 -startdate -noout -in $CERT_PATH)
            TRIM_DATE=$(echo "$CERT_DATE" | cut -d= -f2)
            FORMAT_DATE=$(date -d "$TRIM_DATE" -D "%b %d %T %Y" -I)

            # Update the system time based on the cert time
            echo "Updating date."
            timedatectl set-ntp 0
            sleep 1
            timedatectl set-time $FORMAT_DATE
            sleep 1
            timedatectl set-time 23:59:59
            sleep 1

            # Get the hashes for rootfs and updates
            BOOT_HASH=$(python $SCRIPT_PATH/get_boot_hash.py)
            UPDATE_HASH=$(python $SCRIPT_PATH/get_update_hash.py $UPDATE_FILE_SEARCH)
            echo "Checking boot and update hashes"
            echo "Boot hash: $BOOT_HASH"
            echo "Update hash: $UPDATE_HASH"
            if [ "$BOOT_HASH" == "" ] && [ "$UPDATE_HASH" == "" ]; then 
                echo "Failed to get a hash for comparison"
            elif [ "$BOOT_HASH" == "$UPDATE_HASH" ]; then
                echo "Update image is the same as the one already installed."
            else
                # Move file into position
                echo "Hashes don't match.  Moving forwared with update..."
                BASENAME=$(basename $UPDATE_FILE_SEARCH)
                echo "Moving \"$BASENAME\" to /tmp"
                cp $UPDATE_FILE_SEARCH /tmp

                # Init the install process
                echo "Starting rauc update."
                rauc install /tmp/$BASENAME

                # If install went ok
                if [ $? -eq 0 ]; then
                    # Restart the system
                    echo "Restarting."
                    reboot
                else
                    echo "Update failed. Exiting..."
                fi
            fi
            
            break
        else
            echo "Found more than one update file... Unable to update."
        fi
    else
        echo "Didn't find update directory... Continuing."
    fi
done