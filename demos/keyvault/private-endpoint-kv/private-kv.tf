
terraform {
  required_version = ">= 0.12"
}

#CHANGE BELOW VALUES AS PER YOUR ENVIRONMENT
provider "azurerm" {
  version = ">=2.21.0"
  features{}
  subscription_id = "9441dac5-d868-410e-90a1-ed33727384e5"
  client_id       = "feea1e62-ecf9-4e4d-a959-4b3eba402c98"
  client_secret   = "1d808d4b-340e-453b-8abc-0369134be927"
  tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
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
  tenant_id                   = "72f988bf-86f1-41af-91ab-2d7cd011db47"
 
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
