variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}

# Linux VM Admin User
variable "linux-admin-username" {
  description = "Linux VM Admin User"
  
}

# Windows VM Admin Password
variable "linux-admin-password" {
  description = "Linux VM Admin Password"
  
}

# Windows VM Hostname (limited to 15 characters long)
variable "linux-vm-hostname" {
  description = "Linux VM Hostname"
  
}

# Windows VM Virtual Machine Size
variable "linux-vm-size" {
  type        = string
  description = "Linux VM Size"
  default     = "Standard_B1s"
}


