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