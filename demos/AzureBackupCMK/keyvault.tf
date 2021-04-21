resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_string" "random" {
  length = 10
  special = false
}

data "azurerm_client_config" "current" {}

# Create an Azure Key Vault
resource "azurerm_key_vault" "cmk-kv" {
  name                        = "demo-${random_string.random.result}-cmk-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
}

# Add an access policy allowing our current identity to create a key inside the Azure Key Vault
resource "azurerm_key_vault_access_policy" "user_access_policy" {
  key_vault_id = azurerm_key_vault.cmk-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
      "Get",
      "List",
      "Create"
  ]
}

# Add an access policy allowing our Azure Backup Recovery Vault to encrypt/decrypt with our key
resource "azurerm_key_vault_access_policy" "recovery_vault_access_policy" {
  key_vault_id = azurerm_key_vault.cmk-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_recovery_services_vault.vault-with-cmk.identity[0].principal_id

  key_permissions = [
      "Get",
      "List",
      "UnwrapKey",
      "WrapKey"
  ]
}

# Create our customer-managed key (CMK)
resource "azurerm_key_vault_key" "cmk-key" {
  depends_on = [
    azurerm_key_vault_access_policy.user_access_policy
  ]

  name         = "cmk"
  key_vault_id = azurerm_key_vault.cmk-kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
