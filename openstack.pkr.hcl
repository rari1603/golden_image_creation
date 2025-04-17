packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

variable "openstack_username" {}
variable "openstack_password" {}
variable "openstack_tenant_name" {}
variable "openstack_auth_url" {}
variable "openstack_domain_name" {
  default = "Default"
}

# Source block with OpenStack authentication and image settings
source "openstack" "rhel_image" {
  username           = var.openstack_username
  password           = var.openstack_password
  domain_name        = var.openstack_domain_name
  identity_endpoint  = var.openstack_auth_url
  tenant_name        = "admin"    # <-- Added this line
  insecure           = true
  source_image_name  = "rhel9.4_7feb25"
  image_name         = "patched-rhel9.2"
  flavor             = "c8m16d100"
  ssh_username       = "decoy"
  ssh_password       = "Mycl0ud@456"
  security_groups    = ["default"]
  networks           = ["01143026-8924-4bfe-9a33-479e57820fe0"]
  # use_blockstorage_volume = true
  # volume_size            = 100
}

build {
  name    = "rhel9.2-b2b-image"
  sources = ["source.openstack.rhel_image"]

  provisioner "shell" {
    inline = [
      #"sudo yum update -y",
      #"sudo yum install -y nginx",
       "sudo mkdir /home/ritu-test",
      "echo 'Packer image build complete!' > /home/decoy/info.txt"
    ]
  }
}

