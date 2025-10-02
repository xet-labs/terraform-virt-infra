#!/bin/bash
# Usage: ./import_disk.sh <disk_name> <pool> <tf_resource_name>
disk_name=$1
pool=$2
tf_resource=$3

# Check if the volume exists
if virsh vol-info --pool "$pool" "$disk_name" &>/dev/null; then
    echo "Importing existing disk: $disk_name"
    terraform import "$tf_resource" "$pool/$disk_name"
else
    echo "Disk $disk_name does not exist, skipping import"
fi
