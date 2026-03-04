locals {
  provider_module = {
    aws   = "aws"
    azure = "azure"
    gcp   = "gcp"
  }
}

module "aws_vm" {
  source = "./modules/aws"
  count  = var.platform == "aws" ? 1 : 0

  name_prefix     = var.name_prefix
  admin_username  = var.admin_username
  ssh_pub_key     = var.ssh_pub_key
  provider_config = var.provider_configs["aws"]
}

module "azure_vm" {
  source = "./modules/az"
  count  = var.platform == "azure" ? 1 : 0

  name_prefix     = var.name_prefix
  admin_username  = var.admin_username
  ssh_pub_key     = var.ssh_pub_key
  provider_config = var.provider_configs["azure"]
}

module "gcp_vm" {
  source = "./modules/gcp"
  count  = var.platform == "gcp" ? 1 : 0

  name_prefix     = var.name_prefix
  admin_username  = var.admin_username
  ssh_pub_key     = var.ssh_pub_key
  provider_config = var.provider_configs["gcp"]
}