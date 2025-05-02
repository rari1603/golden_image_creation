variable "openstack_username" {}
variable "openstack_password" {}
variable "openstack_tenant_name" {}
variable "openstack_auth_url" {}
variable "openstack_domain_name" {
  default = "Default"
}

variable "image_name" {
  description = "The name of the image to be created"
  type        = string
  default     = "patched-rhel9.2-${replace(timestamp(), \"[-:T]\", \"\")}"
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
      "echo 'Setting up OpenStack environment...'",
      "export OS_AUTH_URL='${var.openstack_auth_url}'",
      "export OS_USERNAME='${var.openstack_username}'",
      "export OS_PASSWORD='${var.openstack_password}'",
      "export OS_PROJECT_NAME='${var.openstack_tenant_name}'",
      "export OS_USER_DOMAIN_NAME='${var.openstack_domain_name}'",
      "export OS_PROJECT_DOMAIN_NAME='${var.openstack_domain_name}'",
      "export OS_COMPUTE_API_VERSION=2.1",
      "export OS_IMAGE_API_VERSION=2",
      "export OS_INSECURE=true",

      "echo 'Checking if image ${var.image_name} already exists...'",
      "EXISTING_IMAGE=\"$(openstack image list --name ${var.image_name} -f value -c ID)\"",
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
  image_name         = var.image_name
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
      "echo 'Packer image build complete!' > /home/decoy/info.txt"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'Setting up OpenStack environment...'",
      "export OS_AUTH_URL='${var.openstack_auth_url}'",
      "export OS_USERNAME='${var.openstack_username}'",
      "export OS_PASSWORD='${var.openstack_password}'",
      "export OS_PROJECT_NAME='${var.openstack_tenant_name}'",
      "export OS_USER_DOMAIN_NAME='${var.openstack_domain_name}'",
      "export OS_PROJECT_DOMAIN_NAME='${var.openstack_domain_name}'",
      "export OS_COMPUTE_API_VERSION=2.1",
      "export OS_IMAGE_API_VERSION=2",
      "export OS_INSECURE=true",

      "echo 'Saving image locally as ${var.image_name}.qcow2...'",
      "openstack image save ${var.image_name} --file ${var.image_name}.qcow2 || echo 'Warning: Image save failed.'"
    ]
  }
}
