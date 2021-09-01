resource "azurerm_application_insights" "function-appinsights" {
  name                = "function-appinsights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "web"
}