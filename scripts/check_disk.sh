#!/bin/bash
# check_disk.sh <disk_name> <pool>
disk_name=$1
pool=$2

if virsh vol-info --pool "$pool" "$disk_name" &>/dev/null; then
    echo "{\"exists\": \"true\"}"
else
    echo "{\"exists\": \"false\"}"
fi
