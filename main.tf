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

variable "vm_count" {
  default = 3
}

variable "ssh_public_key" {
  description = "Public SSH key to inject into all VMs"
  type        = string
  default     = "" # well export data via terminal 
}

# Host-only network
resource "libvirt_network" "hostonly" {
  name      = "br-host0"
  mode      = "none" # Creates an isolated network (host-only)
  addresses = ["10.1.1.0/24"]
  autostart = true

  dhcp {
    enabled = true
  }
}

# Node-disk base
resource "libvirt_volume" "disk_base" {
  name   = "base-node"
  source = "${path.module}/disk/base.qcow2"
  format = "qcow2"
}

# Node-Disk Root
resource "libvirt_volume" "disk_root" {
  count          = var.vm_count * 2
  name           = "node${count.index + 1}-root.qcow2"
  base_volume_id = libvirt_volume.disk_base.id
  format         = "qcow2"
  pool           = "default"
}

# Node-disk Data
resource "libvirt_volume" "disk_data" {
  count  = var.vm_count * 2
  name   = "node${count.index + 1}-data.qcow2"
  size   = 5 * 1024 * 1024 * 1024 # 5GB data disk
  format = "qcow2"
  pool   = "default"

  lifecycle {
    prevent_destroy = true
  }
}

# Cloud-init disk
resource "libvirt_cloudinit_disk" "node_config" {
  count = var.vm_count * 2
  name  = "node${count.index + 1}-cloudinit.iso"

  user_data = templatefile("${path.module}/cloud-init-user.yaml", {
    hostname = "node${count.index + 1}"
    ssh_key  = var.ssh_public_key
    instance_id  = "node${count.index + 1}"
  })
}

# Create VMs
resource "libvirt_domain" "node" {
  count  = var.vm_count * 2
  name   = "node${count.index + 1}"
  vcpu   = 2
  
  memory {
    dedicated = 170
    floating  = 170 # set equal to dedicated to enable ballooning
  }

  disk {
    volume_id = element(libvirt_volume.disk_root.*.id, count.index) # root disk
  }

  disk {
    volume_id = element(libvirt_volume.disk_data.*.id, count.index) # persistent disk
  }

  lifecycle {
    ignore_changes = [
      network_interface,
      disk[1], # ignore changes to the second disk (persistent data)
    ]
  }

  dynamic "network_interface" {
    for_each = [1]
    content {
      bridge  = count.index < var.vm_count ? "br0" : null
      macvtap = count.index >= var.vm_count ? "wlan0" : null
    }
  }

  # Attach host-only network for SSH/host access
  network_interface {
    network_id = libvirt_network.hostonly.id
    #wait_for_lease = true 
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  # Disable graphical interface for CLI-only mode [2]
  graphics {
    autoport    = false
    listen_type = "none"
  }

  cloudinit = element(libvirt_cloudinit_disk.node_config.*.id, count.index)
}