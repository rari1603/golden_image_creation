variable "openstack_username" {}
variable "openstack_password" {}
variable "openstack_tenant_name" {}
variable "openstack_auth_url" {}
variable "openstack_domain_name" {
  default = "Default"
}

# Dynamically generate image name using a timestamp
locals {
  timestamp  = formatdate("YYYYMMDDHHMMSS", timestamp())  # Format timestamp correctly
  image_name = "patched-rhel9.2-${local.timestamp}"
}

# --- CLEANUP BUILD (Deletes existing image) ---
source "null" "cleanup" {
  communicator = "none"
}

build {
  name    = "cleanup-existing-image"
  sources = ["source.null.cleanup"]

  provisioner "shell-local" {
    inline = [
      "echo \"Setting up OpenStack environment...\"",
      "export OS_AUTH_URL=\"${var.openstack_auth_url}\"",
      "export OS_USERNAME=\"${var.openstack_username}\"",
      "export OS_PASSWORD=\"${var.openstack_password}\"",
      "export OS_PROJECT_NAME=\"${var.openstack_tenant_name}\"",
      "export OS_USER_DOMAIN_NAME=\"${var.openstack_domain_name}\"",
      "export OS_PROJECT_DOMAIN_NAME=\"${var.openstack_domain_name}\"",
      "export OS_COMPUTE_API_VERSION=2.1",
      "export OS_IMAGE_API_VERSION=2",
      "export OS_INSECURE=true",
      "echo \"Checking if image ${local.image_name} already exists...\"",
      "EXISTING_IMAGE=\"$(openstack image list --name ${local.image_name} -f value -c ID)\"",
      "if [ -n \"$EXISTING_IMAGE\" ]; then",
      "  echo \"Image found: $EXISTING_IMAGE. Attempting to delete it...\"",
      "  openstack image delete \"$EXISTING_IMAGE\" || echo 'Warning: Failed to delete image. Continuing...'",
      "else",
      "  echo 'No existing image found.'",
      "fi"
    ]
  }
}

# --- MAIN IMAGE BUILD ---
source "openstack" "rhel_image" {
  username           = var.openstack_username
  password           = var.openstack_password
  domain_name        = var.openstack_domain_name
  identity_endpoint  = var.openstack_auth_url
  tenant_name        = var.openstack_tenant_name
  insecure           = true

  source_image_name  = "rhel9.4_7feb25"
  image_name         = local.image_name
  flavor             = "c8m16d100"
  ssh_username       = "decoy"
  ssh_password       = "Mycl0ud@456"
  security_groups    = ["default"]
  networks           = ["cabbc816-7263-4b07-a537-8c2aca7eb988"]
}

build {
  name    = "rhel9.2-b2b-image"
  sources = ["source.openstack.rhel_image"]

  provisioner "shell" {
    inline = [
      "sudo mkdir /home/ritu-test",
      "echo \"Packer image build complete!\" > /home/decoy/info.txt"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo \"Setting up OpenStack environment...\"",
      "export OS_AUTH_URL=\"${var.openstack_auth_url}\"",
      "export OS_USERNAME=\"${var.openstack_username}\"",
      "export OS_PASSWORD=\"${var.openstack_password}\"",
      "export OS_PROJECT_NAME=\"${var.openstack_tenant_name}\"",
      "export OS_USER_DOMAIN_NAME=\"${var.openstack_domain_name}\"",
      "export OS_PROJECT_DOMAIN_NAME=\"${var.openstack_domain_name}\"",
      "export OS_COMPUTE_API_VERSION=2.1",
      "export OS_IMAGE_API_VERSION=2",
      "export OS_INSECURE=true",
      "echo \"Saving image locally as ${local.image_name}.qcow2...\"",
      "openstack image save ${local.image_name} --file ${local.image_name}.qcow2 || echo 'Warning: Image save failed.'"
    ]
  }
}
