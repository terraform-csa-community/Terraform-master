terraform {
  required_providers {
    azurerm = "~> 2.21"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  features {}
}
resource "azurerm_resource_group" "test" {
  name     = "AppGatewayDemo"
  location = "East US"
}
resource "azurerm_virtual_network" "test" {
  name                = "ApplicationVnet"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "AppGatewaySubnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes       = ["192.168.1.0/27"]
}

resource "azurerm_subnet" "backend" {
  name                 = "ApplicationSubnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes       = ["192.168.1.128/25"]
}

resource "azurerm_public_ip" "test" {
  name                = "AppGwyPIP1"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.test.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.test.name}-rdrcfg"
}
resource "azurerm_application_gateway" "network" {
  name                = "Appgateway1"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  sku {
    name     = "WAF_V2"
    tier     = "WAF_V2"
    capacity = 2
  }
  waf_configuration {
      enabled = true
      firewall_mode = "Detection"
      rule_set_type = "OWASP"
      rule_set_version = "3.0"
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.test.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
resource "azurerm_virtual_machine_scale_set" "test" {
  name                = "AppFarm"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  upgrade_policy_mode  = "Manual"
  os_profile {
    computer_name_prefix = "appvm"
    admin_username       = "adminuser"
    admin_password       = "WelcomeWelcome123"
}

   sku {
   name     = "Standard_DS1_v2"
   tier     = "Standard"
   capacity = 2
 }
  storage_profile_image_reference {
   publisher = "MicrosoftWindowsServer"
   offer     = "WindowsServer"
   sku       = "2016-Datacenter"
   version   = "latest"
 }
   storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  network_profile {
    name    = "AppFarmnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.backend.id
      application_gateway_backend_address_pool_ids = ["${azurerm_application_gateway.network.backend_address_pool[0].id}"]
    }
  }
  extension {
    name                 = "customScript"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.8"
    settings   = <<SETTINGS
      {
        "fileUris":[
            "https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1"
        ],
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1" 
      }
SETTINGS
  }
}