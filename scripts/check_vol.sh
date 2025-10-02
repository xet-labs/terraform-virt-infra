#!/usr/bin/env bash
# reads JSON from stdin: {"name":"node1-data.qcow2","pool":"default"}
# writes JSON to stdout: {"exists":"true","path":"/var/lib/libvirt/images/node1-data.qcow2"}

read -r INPUT
NAME=$(jq -r '.name' <<<"$INPUT")
POOL=$(jq -r '.pool' <<<"$INPUT")

if virsh vol-info --pool "$POOL" "$NAME" &>/dev/null; then
  PATH=$(virsh vol-path --pool "$POOL" "$NAME" 2>/dev/null || echo "")
  jq -n --arg exists "true" --arg path "$PATH" '{exists: $exists, path: $path}'
else
  jq -n --arg exists "false" '{exists: $exists}'
fi
