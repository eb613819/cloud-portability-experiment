output "public_ip" {
  value = (
    var.platform == "aws"   ? module.aws_vm[0].public_ip :
    var.platform == "azure" ? module.azure_vm[0].public_ip :
                               module.gcp_vm[0].public_ip
  )
}

output "ssh_command" {
  value = (
    var.platform == "aws"   ? module.aws_vm[0].ssh_command :
    var.platform == "azure" ? module.azure_vm[0].ssh_command :
                               module.gcp_vm[0].ssh_command
  )
}