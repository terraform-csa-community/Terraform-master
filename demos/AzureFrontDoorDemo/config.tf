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
  count = length(var.locations) 
  name     = "FrontDoorDemo${var.locations[count.index]}"
  location = var.locations[count.index]
}
resource "azurerm_virtual_network" "test" {
  name                = "ApplicationVnet${var.locations[count.index]}"
  count = length(var.locations)
  resource_group_name = azurerm_resource_group.test[count.index].name
  location            = azurerm_resource_group.test[count.index].location
  address_space       = ["192.168.1.0/24"]
}
resource "azurerm_subnet" "backend" {
  name                 = "ApplicationSubnet${var.locations[count.index]}"
  count = length(var.locations)
  resource_group_name  = azurerm_resource_group.test[count.index].name
  virtual_network_name = azurerm_virtual_network.test[count.index].name
  address_prefixes       = ["192.168.1.128/25"]
}
resource "azurerm_public_ip" "test" {
  name                = "PublicIPForLB${var.locations[count.index]}"
  count = length(var.locations)
  location            = azurerm_resource_group.test[count.index].location
  resource_group_name = azurerm_resource_group.test[count.index].name
  allocation_method   = "Static"
}

resource "azurerm_lb" "test" {
  name                = "TestLoadBalancer${var.locations[count.index]}"
  count = length(var.locations)
  location            = azurerm_resource_group.test[count.index].location
  resource_group_name = azurerm_resource_group.test[count.index].name

  frontend_ip_configuration {
    name                 = "FDPublicIPAddress${var.locations[count.index]}"
    public_ip_address_id = azurerm_public_ip.test[count.index].id
  }
}
resource "azurerm_lb_backend_address_pool" "test" {
  resource_group_name = azurerm_resource_group.test[count.index].name
  count = length(var.locations)
  loadbalancer_id     = azurerm_lb.test[count.index].id
  name                = "BackEndAddressPool${var.locations[count.index]}"
}
resource "azurerm_lb_probe" "test" {
  count = length(var.locations)
  resource_group_name = azurerm_resource_group.test[count.index].name
  loadbalancer_id     = azurerm_lb.test[count.index].id
  name                = "http-running-probe${var.locations[count.index]}"
  port                = 80
}
resource "azurerm_lb_rule" "test" {
  count = length(var.locations)
  resource_group_name            = azurerm_resource_group.test[count.index].name
  loadbalancer_id                = azurerm_lb.test[count.index].id
  name                           = "LBRule${var.locations[count.index]}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FDPublicIPAddress${var.locations[count.index]}"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.test[count.index].id
  probe_id                       = azurerm_lb_probe.test[count.index].id
}
resource "azurerm_virtual_machine_scale_set" "test" {
  name                = "AppFarm${var.locations[count.index]}"
  count = length(var.locations)
  location            = azurerm_resource_group.test[count.index].location
  resource_group_name = azurerm_resource_group.test[count.index].name
  upgrade_policy_mode  = "Manual"
  os_profile {
    computer_name_prefix = azurerm_resource_group.test[count.index].location
    admin_username       = "adminuser"
    admin_password       = "PasswordPassword123"
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
    name    = "AppFarmnetworkprofile${var.locations[count.index]}"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.backend[count.index].id
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.test[count.index].id}"]
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
resource "random_string" "random" {
  length = 5
  special = false
}
resource "azurerm_frontdoor" "example" {
  name                                         = "${random_string.random.result}FDtest"
  location                                     = "Global"
  resource_group_name                          = azurerm_resource_group.test[0].name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "exampleRoutingRule1"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["testFDtestEndpoint"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "exampleBackend"
    }
  }

  backend_pool_load_balancing {
    name = "exampleLoadBalancingSettings1"
  }

  backend_pool_health_probe {
    name = "exampleHealthProbeSetting1"
  }

  backend_pool {
    name = "exampleBackend"
    backend {
      host_header = azurerm_public_ip.test[0].ip_address
      address     = azurerm_public_ip.test[0].ip_address
      http_port   = 80
      https_port  = 443
    }
    backend {
      host_header = azurerm_public_ip.test[1].ip_address
      address     = azurerm_public_ip.test[1].ip_address
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "exampleLoadBalancingSettings1"
    health_probe_name   = "exampleHealthProbeSetting1"
  }

  frontend_endpoint {
    name                              = "testFDtestEndpoint"
    host_name                         = "${random_string.random.result}FDtest.azurefd.net"
    custom_https_provisioning_enabled = false
  }
}