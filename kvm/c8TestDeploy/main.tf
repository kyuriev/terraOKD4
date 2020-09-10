

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

#### Define Centos 8 packer image
resource "libvirt_volume" "okd4-services-qcow2" {
  name = "okd4-services.qcow2"
  pool = "default"
  source = "../../packer/centOsKvm/output-qemu/CentOS-8-x86_64-2004"
  format = "qcow2"
}

resource "libvirt_domain" "okd4-services" {
  name = "${var.cluster_name}-sevices"
  memory = var.okd4-services_memory
  vcpu = var.okd4-services_vcpu


  network_interface {
    network_name = "default"
    hostname       = "${var.cluster_name}-services.${var.network_domain}"
    addresses      = [cidrhost(var.network_address,2)]
    wait_for_lease = true

  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.okd4-services-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
