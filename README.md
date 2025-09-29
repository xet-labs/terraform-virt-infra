# node-deb

![License](https://img.shields.io/badge/License-MIT-blue.svg)

A lightweight VM provisioning setup using **Terraform + QEMU/libvirt**.  
I switched from VirtualBox to QEMU for better performance, faster startup, and tighter integration with Linux tooling.  
Terraform makes it easy to define, spin up, and tear down multiple VMs consistently — great for testing, clusters, or dev labs.

---

## Features
- Declarative VM definitions (no manual clicking around)
- Cloud-init support for automatic user/password/SSH key setup
- Works with libvirt (KVM/QEMU) — faster than VirtualBox
- Easy scaling — just change `TF_VAR_vm_count`

---

## Quick Start

```bash
# 1. Clone repo
git clone https://github.com/yourusername/node-deb.git
cd node-deb

# 2. Install dependencies (on Debian/Ubuntu)
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager terraform -y

# 3. Set your SSH key & number of VMs
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
export TF_VAR_vm_count=3

# 4. Apply Terraform config
terraform init
terraform apply -auto-approve

# 5. List VMs and connect
virsh list --all
ssh root@<vm-ip> -p 2200
