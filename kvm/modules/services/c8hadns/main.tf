

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

# cloudinit

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
    vars = {
    domain = var.domain
    prefixIP = var.prefixIP
    octetIP = var.octetIP
  }
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "default"
}

resource "libvirt_domain" "okd4-services" {
  name = "${var.cluster_name}-sevices"
  memory = var.okd4-services_memory
  vcpu = var.okd4-services_vcpu
  cloudinit = libvirt_cloudinit_disk.commoninit.id



  network_interface {
    network_name = "default"
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
        sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../../provisioning/inventory ../../provisioning/okd4-services/main.yml
       EOF
   }
}
