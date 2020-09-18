#### Define and deploy fcosBootstrap
resource "libvirt_volume" "okd4-master-qcow2" {
  name = "okd4-bootstrap.qcow2"
  pool = "default"
  source = "../../packer/fcosKvmMaster-1/output-qemu/fcos-master.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "okd4-master-1" {
  name = "${var.cluster_name}-master-1"
  memory = var.okd4-master_memory
  vcpu = var.okd4-master_vcpu



  network_interface {
    network_name = "default"
  }


  console {
    type = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.okd4-master-qcow2.id
  }


  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}