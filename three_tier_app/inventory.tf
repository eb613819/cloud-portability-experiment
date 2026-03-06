resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.yml"

  content = yamlencode({
    all = {
      children = {
        web_group = {
          hosts = {
            web = {
              ansible_host               = local.web_public_ip
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
            }
          }
        }
        app_group = {
          hosts = {
            app = {
              ansible_host               = local.app_private_ip
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o StrictHostKeyChecking=no -o ProxyJump=${var.admin_username}@${local.web_public_ip}"
            }
          }
        }
        db_group = {
          hosts = {
            db = {
              ansible_host               = local.db_private_ip
              ansible_user               = var.admin_username
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o StrictHostKeyChecking=no -o ProxyJump=${var.admin_username}@${local.web_public_ip}"
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