terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {

  }
}

resource "azurerm_resource_group" "rtrg" {
  name     = "serviceTagRouteTableTest1"
  location = "EastUS2"
}

resource "azurerm_route_table" "rt" {
  name                = "serviceTagRouteTableTest1"
  location            = azurerm_resource_group.rtrg.location
  resource_group_name = azurerm_resource_group.rtrg.name
}

resource "azurerm_route" "nva_route" {
  name                = "NVA"
  resource_group_name = azurerm_resource_group.rtrg.name
  route_table_name    = azurerm_route_table.rt.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.0.1"
}

//Full list of Service Tags available here https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview

resource "azurerm_route" "service_tag1" {
  name                = "AzureBackup"
  resource_group_name = azurerm_resource_group.rtrg.name
  route_table_name    = azurerm_route_table.rt.name
  address_prefix      = "AzureBackup"
  next_hop_type       = "Internet"
}
