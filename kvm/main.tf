

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
resource "libvirt_pool" "default" {
  name = var.libvirt_storage_pool_name
  type = "dir"
  path = var.libvirt_storage_pool_path
}
#### Define Centos 8 packer image
resource "libvirt_volume" "okd4-services-qcow2" {
  name = "okd4-services.qcow2"
  pool = libvirt_pool.default.name
  source = "../packer/centOsKvm/output-qemu/fedoraCoreOs-packer.qcow2"
  format = "qcow2"

  provisioner "local-exec" {
     command = <<EOF
       sudo qemu-img resize "${var.libvirt_storage_pool_path}/${libvirt_volume.okd4-services-qcow2.name}" "${var.okd4-services_disk}"G   # TODO remove sudo
       EOF
   }
}

resource "libvirt_domain" "okd4-services" {
  name   = "${var.cluster_name}-sevices"
  memory = var.okd4-services_memory
  vcpu   = var.okd4-services_vcpu


  network_interface {
    network_name = "default"
    hostname       = "${var.cluster_name}-services.${var.network_domain}"
    addresses      = [cidrhost(var.network_address,2)]
    wait_for_lease = true

  }

  boot_device {
    dev = [ "hd", "cdrom"]
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

  provisioner "local-exec" {
     command = <<EOF
        ansible-playbook -i ./ansible/inventory ./ansible/tasks/haproxy_config.yml -vvv
       EOF
   }

}

#### Define and deploy CoreOs
resource "libvirt_volume" "fedoraCoreOs_image" {
  name = "fedoraCoreOs_image"
  pool = libvirt_pool.default.name
  #source = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20200824.3.0/x86_64/fedora-coreos-32.20200824.3.0-qemu.x86_64.qcow2.xz"
  source = "../packer/fedoraCoreOsKvm/output-qemu/fedoraCoreOs-packer.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "os_volume" {
  name           = "os_volume-${count.index}"
  base_volume_id = libvirt_volume.fedoraCoreOs_image.id
  count          = var.VM_COUNT
}

### Deploy virtual machines
#### Deploy load balancer

#### Deploy working nodes
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
