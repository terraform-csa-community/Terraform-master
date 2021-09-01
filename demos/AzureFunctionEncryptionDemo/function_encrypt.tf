resource "azurerm_storage_account" "function-encrypt" {
  name                     = "funcencryptstr${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "function-encrypt" {
  name                       = "function-encrypt-${random_string.random.result}"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  app_service_plan_id        = azurerm_app_service_plan.function-plan.id
  storage_account_name       = azurerm_storage_account.function-encrypt.name
  storage_account_access_key = azurerm_storage_account.function-encrypt.primary_access_key
  os_type                    = "linux"

  // https://docs.microsoft.com/en-us/azure/azure-functions/set-runtime-version
  version = "~3"


  // Identity used by our function app to access KeyVault
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function-encrypt-msi.id]
  }

  site_config {
    linux_fx_version          = "Python|3.9"
    use_32_bit_worker_process = false
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.function-appinsights.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.function-appinsights.connection_string
    // TODO: Leverage managed service identity (MSI) for EventHub Connection string
    EVENTHUB_CONNECTION_STRING = azurerm_eventhub_authorization_rule.function-encrypt.primary_connection_string
    EVENTHUB_NAME              = azurerm_eventhub.example.name
    KEY_VAULT_URL              = azurerm_key_vault.cmk-kv.vault_uri
    KEY_NAME                   = azurerm_key_vault_key.cmk-key.name
    KEY_VERSION                = azurerm_key_vault_key.cmk-key.version
    FUNCTIONS_WORKER_RUNTIME   = "python"
    AZURE_CLIENT_ID            = azurerm_user_assigned_identity.function-encrypt-msi.client_id
  }
}
