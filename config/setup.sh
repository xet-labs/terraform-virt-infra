#!/usr/bin/env bash

# create br to be used in vm
nmcli connection add type bridge con-name br-eth0 ifname br-eth0
#nmcli connection add type bridge-slave con-name eth-in ifname eth0 master br-eth0
nmcli connection modify eth-in connection.master br-eth0
nmcli connection up br-eth0
nmcli connection up eth-in

