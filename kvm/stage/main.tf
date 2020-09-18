

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



module "c8hadns" {
  source = "../modules/services/c8hadns"
}

## Add bootstrap module
module "okd4-bootstrap" {
  source = "../modules/services/okd4-bootstrap"
  depends_on = [module.c8hadns]
}

## Add bootstrap module
module "okd4-master-1" {
  source = "../modules/services/okd4-master-1"
}