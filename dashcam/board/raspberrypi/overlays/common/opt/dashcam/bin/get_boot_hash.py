import os, json

# Get rauc info
stream = os.popen('rauc --output-format=json status --detailed')
output = stream.read()
info = json.loads(output)

# Determine what partition has been booted
bootSlot = info['boot_primary']

# Loop through all slots available
for slot in info['slots']:
    # Proceed further if this is the slot we're looking for
    if bootSlot in slot:
        # Get slot info
        slotInfo = slot[bootSlot]

        # Output boot slot checksum
        print(slotInfo['slot_status']['checksum']['sha256'])
        break
