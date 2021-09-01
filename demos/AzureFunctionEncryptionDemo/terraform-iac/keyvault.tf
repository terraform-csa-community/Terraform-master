data "azurerm_client_config" "current" {}

# Create an Azure Key Vault
resource "azurerm_key_vault" "cmk-kv" {
  name                     = "demo-${random_string.random.result}-kv"
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
}

# Add an access policy allowing our current identity to create a key inside the Azure Key Vault
# (this is used so Terraform can create the CMK below, azurerm_key_vault_key)
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

# Add an access policy for our encryption Function
resource "azurerm_key_vault_access_policy" "function_encrypt_access_policy" {
  key_vault_id = azurerm_key_vault.cmk-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.function-encrypt-msi.principal_id

  key_permissions = [
    "Get",
    "Encrypt"
  ]
}

# Add an access policy for our decryption Function
resource "azurerm_key_vault_access_policy" "function_decrypt_access_policy" {
  key_vault_id = azurerm_key_vault.cmk-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.function-decrypt-msi.principal_id

  key_permissions = [
    "Get",
    "Decrypt"
  ]
}

# Create our customer-managed key (CMK) for encryption/decryption
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
    "encrypt"
  ]
}
