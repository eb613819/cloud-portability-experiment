output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "app_private_ip" {
  value = azurerm_network_interface.app.private_ip_address
}

output "db_private_ip" {
  value = azurerm_network_interface.db.private_ip_address
}
