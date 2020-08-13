provider "azurerm" {
  version = "= 2.21"
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

resource "azurerm_windows_virtual_machine" "test" {
  name                  = "${var.prefix}-vm"  
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.myvm1nic.id]
  size                  = var.windows-vm-size
  computer_name         = var.windows-vm-hostname
  admin_username        = var.windows-admin-username
  admin_password        = var.windows-admin-password

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows-2019-sku
    version   = "latest"
  }

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                 = "MicrosoftMonitoringAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.test.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
  settings = <<BASE_SETTINGS
{

 "workspaceId": "${var.lga_id}"

}

BASE_SETTINGS

  protected_settings = <<PROTECTED_SETTINGS

{

 "workspaceKey": "${var.lga_key}"

}

PROTECTED_SETTINGS
}


 