output "static_public_ip" {
  value = azurerm_public_ip.external.ip_address
}
