provider "azurerm" {
  version = "= 2.21.0"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "myvnet" {
  name = "${var.prefix}-network"
  address_space = ["192.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "samplesubnet" {
  name = "${var.prefix}-subnet"
  resource_group_name =  azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefix = "192.0.1.0/24"
}

resource "azurerm_public_ip" "myvm1publicip" {
  name = "${var.prefix}-pip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_network_interface" "myvm1nic" {
  name = "${var.prefix}-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.samplesubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myvm1publicip.id
  }
}

resource "azurerm_virtual_machine" "demo" {
  name                  = "${var.prefix}-vm"  
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.myvm1nic.id]
  vm_size               = var.linux-vm-size
  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {

   computer_name = var.linux-vm-hostname
   admin_username = var.linux-admin-username
   admin_password = var.linux-admin-password
  }

  os_profile_linux_config {
      disable_password_authentication = false
  }

  storage_os_disk {
    name              = "demoosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
}
