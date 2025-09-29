#!/usr/bin/env bash
echo "[+] Setup 'br0' -> 'eth0' host only net iface"
sudo nmcli connection add type bridge con-name br0 ifname br0
# Add eth0 to the bridge
sudo nmcli connection add type bridge-slave con-name br0-eth0 ifname eth0 master br0
# Bring the bridge up
sudo nmcli connection up br0
sudo nmcli connection up br0-eth0

# echo "[+] Setup share host only net iface"
# sudo nmcli connection add type bridge ifname br-vnet0 con-name br-vnet0
# sudo nmcli connection modify br-vnet0 ipv4.addresses 10.9.9.1/24 ipv4.method manual
# sudo nmcli connection up br-vnet0

