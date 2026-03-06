output "web_public_ip" {
  value = (
    var.platform == "aws"   ? module.aws_vm[0].web_public_ip :
    var.platform == "azure" ? module.azure_vm[0].web_public_ip :
                               module.gcp_vm[0].web_public_ip
  )
}

output "app_private_ip" {
  value = (
    var.platform == "aws"   ? module.aws_vm[0].app_private_ip :
    var.platform == "azure" ? module.azure_vm[0].app_private_ip :
                               module.gcp_vm[0].app_private_ip
  )
}

output "db_private_ip" {
  value = (
    var.platform == "aws"   ? module.aws_vm[0].db_private_ip :
    var.platform == "azure" ? module.azure_vm[0].db_private_ip :
                               module.gcp_vm[0].db_private_ip
  )
}

output "wordpress_url" {
  value       = "https://${var.wordpress_domain}"
  description = "WordPress site URL"
}