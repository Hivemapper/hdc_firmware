#!/bin/sh
#
# This script is a post-update handler called by RAUC.

# Tell the next bootbit instance that it's testing a branch new update.
fw_setenv UNBOOTED_UPDATE 1

