
################################################################################
# ENV VARS
################################################################################

# https://www.terraform.io/docs/commands/environment-variables.html
variable "VM_COUNT" {
  default = 3
  type = number
}

variable "VM_HOSTNAME" {
  default = "vm"
  type = string
}

variable "VM_USER" {
  default = "kyuriev"
  type = string
}

################################################################################
# PROVIDERS
################################################################################

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}


################################################################################
# DATA TEMPLATES
################################################################################



################################################################################
# RESOURCES
################################################################################

resource "libvirt_volume" "fedoraCoreOs_image" {
  name = "fedoraCoreOs_image"
  pool = "default"
  #source = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20200824.3.0/x86_64/fedora-coreos-32.20200824.3.0-qemu.x86_64.qcow2.xz"
  source = "../packer/output-qemu/fedoraCoreOs-packer.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "os_volume" {
  name           = "os_volume-${count.index}"
  base_volume_id = libvirt_volume.fedoraCoreOs_image.id
  count          = var.VM_COUNT
}

# Define KVM domain to create
resource "libvirt_domain" "vm" {
  count  = var.VM_COUNT
  name   = "${var.VM_HOSTNAME}-${count.index}"
  memory = "1024"
  vcpu   = 1


  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index)
  }


  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}
