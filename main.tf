terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "vm_grp_count" {
  default = 2
}

variable "ssh_public_key" {
  description = "Public SSH key to inject into all VMs"
  type        = string
  default     = ""
}

# --- VM map: merge two groups ---
locals {
  vm_map = merge(
    { for i in range(var.vm_grp_count) : "node${i + 1}" => {
        memory   = 320
        vcpu     = 2
        net_name = "net-eth0"
        pool = "default"
      }
    },
    { for i in range(var.vm_grp_count, var.vm_grp_count * 2) : "node${i + 1}" => {
        memory   = 320
        vcpu     = 2
        net_name = "net-wlan0"
        pool = "default"
      }
    }
  )
}

resource "libvirt_volume" "disk_base" {
  name   = "node-base"
  source = "${path.module}/disk/base.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "disk_root" {
  for_each       = local.vm_map
  name           = "${each.key}-root.qcow2"
  base_volume_id = libvirt_volume.disk_base.id
  format         = "qcow2"
  pool   = each.value.pool
}

# call external script per VM to check if data disk exists
data "external" "disk_exists" {
  for_each = local.vm_map

  program = [ "${path.module}/scripts/check_vol.sh" ]
  query = {
    name = "${each.key}-data.qcow2"
    pool = each.value.pool
  }
}

# Create only the data volumes that do NOT already exist
resource "libvirt_volume" "disk_data" {
  for_each = {
    for k, v in local.vm_map :
    k => v if data.external.disk_exists[k].result.exists == "false"
  }

  name   = "${each.key}-data.qcow2"
  size   = 5 * 1024 * 1024 * 1024
  format = "qcow2"
  pool   = each.value.pool

  lifecycle {
    # protect data volumes created by Terraform from accidental removal
    prevent_destroy = true
    ignore_changes  = [size]
  }
}

# For volumes that already exist, expose them to Terraform via data source
# (so we can attach their id)
data "libvirt_volume" "disk_data_existing" {
  for_each = {
    for k, v in local.vm_map :
    k => v if data.external.disk_exists[k].result.exists == "true"
  }

  # attributes used by provider: name & pool
  name = "${each.key}-data.qcow2"
  pool = each.value.pool
}

# --- Cloud-init disks ---
resource "libvirt_cloudinit_disk" "node_config" {
  for_each = local.vm_map

  name = "${each.key}-cloudinit.iso"

  user_data = templatefile("${path.module}/cloud-init/user.yaml", {
    hostname    = each.key
    ssh_key     = var.ssh_public_key
    instance_id = each.key
    memory      = each.value.memory
  })
}

# --- Domains / VMs ---
resource "libvirt_domain" "node" {
  for_each = local.vm_map

  name   = each.key
  memory = each.value.memory
  vcpu   = each.value.vcpu

  # root disk
  disk {
    volume_id = libvirt_volume.disk_root[each.key].id
  }

  # persistent data disk
  disk {
    volume_id = data.external.disk_exists[each.key].result.exists == "true" ? data.libvirt_volume.disk_data_existing[each.key].id : libvirt_volume.disk_data[each.key].id
  }
  lifecycle {
    ignore_changes = [network_interface, disk[1]] # ignore changes to persistent disk & NIC
  }

  network_interface {
    network_name = each.value.net_name
  }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    autoport    = false
    listen_type = "none"
  }

  cloudinit = libvirt_cloudinit_disk.node_config[each.key].id


  depends_on = [
    libvirt_volume.disk_root,
    libvirt_volume.disk_data,
    libvirt_cloudinit_disk.node_config,
  ]
}
