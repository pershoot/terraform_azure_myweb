output "static_public_ip" {
  value = azurerm_public_ip.external.ip_address
}

resource "local_file" "hosts" {
  content              = "[vps]\n${azurerm_public_ip.external.ip_address} ansible_connection=ssh ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.prefix} instance=${azurerm_virtual_machine.myweb.name} instance_rg=${azurerm_resource_group.myweb.name} instance_nsg=${azurerm_network_security_group.myweb.name}"
  filename             = pathexpand("~/dev/ansible/hosts-azure")
  directory_permission = 0754
  file_permission      = 0664
}
