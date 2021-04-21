resource "azurerm_recovery_services_vault" "vault-with-cmk" {
  name                  = "recovery-vault-with-cmk"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  sku                   = "Standard"
  
  identity  {
      type = "SystemAssigned"
      }
}

# Why are we calling PowerShell here? Unfortunately, enabling CMK is not natively supported in Terraform
resource "null_resource" "enable-cmk-on-recovery-vault" {
  depends_on = [ azurerm_key_vault_key.cmk-key ]
    provisioner "local-exec" {      
      command     = "Set-AzRecoveryServicesVaultProperty -EncryptionKeyId ${azurerm_key_vault_key.cmk-key.id} -KeyVaultSubscriptionId ${data.azurerm_client_config.current.subscription_id} -VaultId ${azurerm_recovery_services_vault.vault-with-cmk.id}"
      interpreter = ["PowerShell", "-Command"]
   }
}