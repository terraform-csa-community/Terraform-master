variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}

# Windows VM Admin User
variable "windows-admin-username" {
  description = "Windows VM Admin User"
  
}

# Windows VM Admin Password
variable "windows-admin-password" {
  description = "Windows VM Admin Password"
  
}

# Windows VM Hostname (limited to 15 characters long)
variable "windows-vm-hostname" {
  description = "Windows VM Hostname"
  
}

# Windows VM Virtual Machine Size
variable "windows-vm-size" {
  type        = string
  description = "Windows VM Size"
  default     = "Standard_B1s"
}


## OS Image ##


# Windows Server 2019 SKU used to build VMs
variable "windows-2019-sku" {
  type        = string
  description = "Windows Server 2019 SKU used to build VMs"
  default     = "2019-Datacenter"
}

# Windows Server 2016 SKU used to build VMs
variable "windows-2016-sku" {
  type        = string
  description = "Windows Server 2016 SKU used to build VMs"
  default     = "2016-Datacenter"
}

# Windows Server 2012 R2 SKU used to build VMs
variable "windows-2012-sku" {
  type        = string
  description = "Windows Server 2012 R2 SKU used to build VMs"
  default     = "2012-R2-Datacenter"
}

variable "lga_id" {
description = "Workspace ID for Log Analytics"    
}

variable "lga_key" {
description = "Workspace key for Log Analytics"    
}
