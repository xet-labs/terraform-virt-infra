#!/bin/bash
# import_disks.sh
# Automatically import existing libvirt data disks into Terraform state
# Usage: ./import_disks.sh <vm_name_prefix> <count> <pool>

VM_PREFIX="$1"
VM_COUNT="$2"
POOL="${3:-default}"

for i in $(seq 1 "$VM_COUNT"); do
  VM_NAME="${VM_PREFIX}${i}"
  DISK_NAME="${VM_NAME}-data.qcow2"

  if virsh vol-info --pool "$POOL" "$DISK_NAME" &>/dev/null; then
    echo "Importing existing disk: $DISK_NAME"
    terraform import "libvirt_volume.disk_data[\"$VM_NAME\"]" "$POOL/$DISK_NAME"
  else
    echo "Disk $DISK_NAME does not exist, skipping..."
  fi
done
