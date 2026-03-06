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
