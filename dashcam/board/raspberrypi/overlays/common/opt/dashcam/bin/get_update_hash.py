import json, os, sys

# Store bundle path
bundlePath = sys.argv[1]

# Validate that the bundle path exists
if os.path.exists(bundlePath):
    # Get bundle info
    stream = os.popen('rauc --output-format=json info {}'.format(bundlePath))
    info = stream.read()
    bundleInfo = json.loads(info)

    # Loop through all images in the bundle
    for image in bundleInfo['images']:
        # If the current image is the rootfs
        if 'rootfs' in image:
            # Get image info
            imageInfo = image['rootfs']

            # Output update image the checksum
            print(imageInfo['checksum'])
            break
