# Create a Resource Group
resource "azurerm_resource_group" "myweb" {
  name     = "${var.prefix}-rg"
  location = var.region

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Create a DNS Zone
resource "azurerm_dns_zone" "myweb" {
  name                = "${var.prefix}.com"
  resource_group_name = azurerm_resource_group.myweb.name

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Create a Virtual Network
resource "azurerm_virtual_network" "myweb" {
  name                = "${var.prefix}-net"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myweb.location
  resource_group_name = azurerm_resource_group.myweb.name

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Add a Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myweb.name
  virtual_network_name = azurerm_virtual_network.myweb.name
  address_prefix       = "10.0.1.0/24"
}

# Allocate a Static Public IP
resource "azurerm_public_ip" "external" {
  name                = "external"
  location            = var.region
  resource_group_name = azurerm_resource_group.myweb.name
  allocation_method   = "Static"

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Create a Network Security Group and allow inbound port(s)
resource "azurerm_network_security_group" "myweb" {
  name                = "${var.prefix}-nsg"
  location            = var.region
  resource_group_name = azurerm_resource_group.myweb.name

  security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Create a Network Interface with a Dynamic Private IP
resource "azurerm_network_interface" "myweb" {
  name                      = "${var.prefix}-nic"
  location                  = azurerm_resource_group.myweb.location
  resource_group_name       = azurerm_resource_group.myweb.name
  network_security_group_id = azurerm_network_security_group.myweb.id

  ip_configuration {
       name                          = "${var.prefix}-nic_conf"
       subnet_id                     = azurerm_subnet.internal.id
       private_ip_address_allocation = "Dynamic"
       public_ip_address_id          = azurerm_public_ip.external.id
    }

  tags = {
        Site = "${var.prefix}.com"
    }
}

# Create an Ubuntu Virtual Machine with key based access and run a script on boot; use a Standard SSD
resource "azurerm_virtual_machine" "myweb" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.myweb.location
  resource_group_name   = azurerm_resource_group.myweb.name
  network_interface_ids = [azurerm_network_interface.myweb.id]
  vm_size               = "Basic_A1"

  storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

  storage_os_disk {
      name              = "${var.prefix}-disk"
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "StandardSSD_LRS"
    }

  os_profile {
      computer_name  = var.prefix
      admin_username = "ubuntu"
      custom_data    = data.template_file.init_script.rendered
    }

  os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/ubuntu/.ssh/authorized_keys"
            key_data = file("~/.ssh/${var.prefix}.pub")
          }
    }

  tags = {
        Site = "${var.prefix}.com"
    }
}
