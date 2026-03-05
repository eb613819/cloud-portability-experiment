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

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.yml"

  content = yamlencode({
    all = {
      children = {
        web_group = {
          hosts = {
            web = {
              ansible_host               = (
                var.platform == "aws"   ? module.aws_vm[0].web_public_ip :
                var.platform == "azure" ? module.azure_vm[0].web_public_ip :
                                           module.gcp_vm[0].web_public_ip
              )
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
            }
          }
        }
        app_group = {
          hosts = {
            app = {
              ansible_host               = (
                var.platform == "aws"   ? module.aws_vm[0].app_private_ip :
                var.platform == "azure" ? module.azure_vm[0].app_private_ip :
                                           module.gcp_vm[0].app_private_ip
              )
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o StrictHostKeyChecking=no -o ProxyJump=${var.admin_username}@${(
                var.platform == "aws"   ? module.aws_vm[0].web_public_ip :
                var.platform == "azure" ? module.azure_vm[0].web_public_ip :
                                           module.gcp_vm[0].web_public_ip
              )}"
            }
          }
        }
        db_group = {
          hosts = {
            db = {
              ansible_host               = (
                var.platform == "aws"   ? module.aws_vm[0].db_private_ip :
                var.platform == "azure" ? module.azure_vm[0].db_private_ip :
                                           module.gcp_vm[0].db_private_ip
              )
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o StrictHostKeyChecking=no -o ProxyJump=${var.admin_username}@${(
                var.platform == "aws"   ? module.aws_vm[0].web_public_ip :
                var.platform == "azure" ? module.azure_vm[0].web_public_ip :
                                           module.gcp_vm[0].web_public_ip
              )}"
            }
          }
        }
      }
    }
  })

  depends_on = [
    module.aws_vm,
    module.azure_vm,
    module.gcp_vm
  ]
}
