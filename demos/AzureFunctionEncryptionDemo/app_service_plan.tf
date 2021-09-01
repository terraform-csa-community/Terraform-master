resource "azurerm_app_service_plan" "function-plan" {
  name                = "functions-service-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true // True for Linux, False for Windows

  // Consumption plan (Serverless) SKU
  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  lifecycle {
    ignore_changes = [
      kind // We create it as Linux but Azure returns it later as functionapp, ignore for now, TODO: Fix later
    ]
  }
}