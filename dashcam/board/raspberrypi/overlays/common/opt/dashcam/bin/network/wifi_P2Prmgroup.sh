# This removes and latent state of the P2P group.
# This must be run if a disconnect occurs

wpa_cli -i wlan0 p2p_flush
sleep 1
wpa_cli -i wlan0 set config_methods
sleep 1

interface=$(ip link | grep -E -o 'p2p-wlan0-[0-9]+')
wpa_cli -i wlan0 p2p_group_remove $interface
