# Azure Backup with customer-managed keys (CMK)

## Overview

This Terraform code creates an Azure Backup Recovery Vault using customer-managed keys (CMK). 
1. A recovery vault is created with a system assigned managed identity
2. A Key Vault is created with purge protection and soft delete enabled, and includes two (2) access policies
3. The first access policy allows our identity (that is, our Azure identity executing this Terraform code)  permissions to create a key inside the Key Vault
4. The second access policy allows the Azure Backup Recovery Vault to wrap and unwrap, which lets it use the key for encryption/decryption
5. Lastly, Terraform uses a 'local-exec' provisioner to call PowerShell to enable CMK on the recovery vault with the key we generated from above. Why do we call PowerShell? Unfortunately, enabling CMK is not natively supported in Terraform

This Terraform code follows the documentation on Recovery Vault from [here](https://docs.microsoft.com/en-us/azure/backup/encryption-at-rest-with-cmk#configuring-a-vault-to-encrypt-using-customer-managed-keys)

