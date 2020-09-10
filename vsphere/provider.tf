terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}
