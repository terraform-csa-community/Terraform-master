
resource "azurerm_user_assigned_identity" "function-encrypt-msi" {
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  name = "function-encrypt-msi"
}

resource "azurerm_user_assigned_identity" "function-decrypt-msi" {
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  name = "function-decrypt-msi"
}

