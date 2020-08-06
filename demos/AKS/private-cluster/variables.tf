variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
    default = 3
}

variable location {
    default = "eastus"
}

variable resource_group_name {
    default = "private-aks-demo"
}


