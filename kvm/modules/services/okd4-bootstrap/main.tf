#### Define and deploy fcosBootstrap
resource "libvirt_volume" "okd4-bootstrap-qcow2" {
  name = "okd4-bootstrap.qcow2"
  pool = "default"
  source = "../../packer/fcosKvmBootstrap/output-qemu/fedoraCoreOs-packer.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "okd4-services" {
  name = "${var.cluster_name}-bootstrap"
  memory = var.okd4-bootstrap_memory
  vcpu = var.okd4-bootstrap_vcpu



  network_interface {
    network_name = "default"
  }


  console {
    type = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.okd4-bootstrap-qcow2.id
  }


  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}