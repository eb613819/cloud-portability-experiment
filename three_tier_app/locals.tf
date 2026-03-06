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