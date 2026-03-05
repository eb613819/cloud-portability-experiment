locals {
  provider_module = {
    aws   = "aws"
    azure = "azure"
    gcp   = "gcp"
  }

  web_public_ip = (
    var.platform == "aws"   ? module.aws_vm[0].web_public_ip :
    var.platform == "azure" ? module.azure_vm[0].web_public_ip :
                               module.gcp_vm[0].web_public_ip
  )
  app_private_ip = (
    var.platform == "aws"   ? module.aws_vm[0].app_private_ip :
    var.platform == "azure" ? module.azure_vm[0].app_private_ip :
                               module.gcp_vm[0].app_private_ip
  )
  db_private_ip = (
    var.platform == "aws"   ? module.aws_vm[0].db_private_ip :
    var.platform == "azure" ? module.azure_vm[0].db_private_ip :
                               module.gcp_vm[0].db_private_ip
  )
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

resource "null_resource" "namecheap_dns" {
  triggers = {
    platform = var.platform
    web_ip   = local.web_public_ip
  }

  provisioner "local-exec" {
    command = <<EOT
curl -s "https://api.namecheap.com/xml.response\
?ApiUser=${var.namecheap_username}\
&ApiKey=${var.namecheap_api_key}\
&UserName=${var.namecheap_username}\
&ClientIp=${var.namecheap_client_ip}\
&Command=namecheap.domains.dns.setHosts\
&SLD=evanbrooks\
&TLD=me\
&HostName1=@&RecordType1=A&Address1=185.199.108.153&TTL1=300\
&HostName2=@&RecordType2=A&Address2=185.199.109.153&TTL2=300\
&HostName3=@&RecordType3=A&Address3=185.199.110.153&TTL3=300\
&HostName4=@&RecordType4=A&Address4=185.199.111.153&TTL4=300\
&HostName5=www&RecordType5=CNAME&Address5=eb613819.github.io.&TTL5=300\
&HostName6=blog&RecordType6=A&Address6=${local.web_public_ip}&TTL6=300"
EOT
  }

  depends_on = [local_file.ansible_inventory]
}

resource "null_resource" "wait_for_ssh_web" {
  triggers = {
    platform = var.platform
    web_ip   = local.web_public_ip
  }
  connection {
    type    = "ssh"
    host    = local.web_public_ip
    user    = var.admin_username
    agent   = true
    timeout = "5m"
  }
  provisioner "remote-exec" {
    inline = ["echo SSH ready on web"]
  }
  depends_on = [
    local_file.ansible_inventory,
    null_resource.namecheap_dns
  ]
}

resource "null_resource" "wait_for_ssh_app" {
  triggers = {
    platform = var.platform
    app_ip   = local.app_private_ip
  }
  connection {
    type         = "ssh"
    host         = local.app_private_ip
    user         = var.admin_username
    agent        = true
    timeout      = "5m"
    bastion_host = local.web_public_ip
    bastion_user = var.admin_username
  }
  provisioner "remote-exec" {
    inline = ["echo SSH ready on app"]
  }
  depends_on = [null_resource.wait_for_ssh_web]
}

resource "null_resource" "wait_for_ssh_db" {
  triggers = {
    platform = var.platform
    db_ip    = local.db_private_ip
  }
  connection {
    type         = "ssh"
    host         = local.db_private_ip
    user         = var.admin_username
    agent        = true
    timeout      = "5m"
    bastion_host = local.web_public_ip
    bastion_user = var.admin_username
  }
  provisioner "remote-exec" {
    inline = ["echo SSH ready on db"]
  }
  depends_on = [null_resource.wait_for_ssh_web]
}

resource "null_resource" "ansible" {
  triggers = {
    platform = var.platform
    web_ip   = local.web_public_ip
  }
  provisioner "local-exec" {
    command     = "ansible-playbook site.yml"
    working_dir = "${path.module}/ansible"
  }
  depends_on = [
    null_resource.wait_for_ssh_app,
    null_resource.wait_for_ssh_db
  ]
}

output "wordpress_url" {
  value       = "https://blog.evanbrooks.me"
  description = "WordPress site URL"
}