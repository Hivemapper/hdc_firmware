#!/bin/bash
#
# Default file used by the update.py test when we power cycle the target.  In our case we are
# using a power relay that can be controlled using an HTTP command.
#
# Dependencies:
# - curl

RELAY_IP=192.168.1.201

# See https://www.controlbyweb.com/webrelay/webrelay_users_manual.pdf for docs on this URL.
# Note we use stateFull.xml over state.xml since state.xml doesn't return the right headers
# and causes the Python requests library to error.  (Of course we're using curl here, but regardless).
curl -s -o /dev/null --connect-timeout 0.1 -X GET http://${RELAY_IP}/stateFull.xml?relayState=2
