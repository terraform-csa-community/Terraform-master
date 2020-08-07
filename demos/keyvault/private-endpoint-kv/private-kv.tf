
terraform {
  required_version = ">= 0.12"
}

#CHANGE BELOW VALUES AS PER YOUR ENVIRONMENT
provider "azurerm" {
  version = ">=2.21.0"
  features{}
  subscription_id = "XXXXXXXX"
  client_id       = "XXXXXXXXX"
  client_secret   = "XXXXXXXXX"
  tenant_id       = "XXXXXXXXX"
}

resource "azurerm_resource_group" "private-example-kv" {
  name     = var.resource_group_name
  location = var.location
}
resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

resource "azurerm_virtual_network" "example" {
  name                = "${random_string.random.result}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "example" {
  name                 = "${random_string.random.result}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = "10.0.1.0/24"

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_key_vault" "example-kv" {
  name                        = "${random_string.random.result}-examplekv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = "XXXXXX"
 
  sku_name = "standard"
}
 

resource "azurerm_private_endpoint" "example" {
  name                = "${random_string.random.result}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "${random_string.random.result}-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.example-kv.id
    subresource_names              = [ "vault" ]
    is_manual_connection           = false
  }
}
