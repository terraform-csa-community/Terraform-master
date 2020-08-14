# declare provider variables
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

# declare location variable

variable "location" {
    description = "Location for regional hub and spoke configuration"
    default = "EastUS"
}

# declare spoke networks
variable "spoke_networks" {
    type = map(object({
        name                    = string
        prefix                  = string
        address_space           = list(string)
        subnets = map(object({
            name                = string
            address_prefixes    = list(string)
        }))
    }))
    default = {
        spoke1 = {
            name = "spoke1"
            prefix = "sp1"
            address_space = ["10.2.0.0/16"]
            subnets = {
                bastionsubnet ={
                    name                = "AzureBastionSubnet"
                    address_prefixes    = ["10.2.1.0/24"]
                }
                defaultsubnet ={
                    name                = "default"
                    address_prefixes    = ["10.2.2.0/24"]
                }
            }
        }
        spoke2 = {
            name = "spoke2"
            prefix = "sp2"
            address_space = ["10.3.0.0/16"]
            subnets = {
                bastionsubnet ={
                    name                = "AzureBastionSubnet"
                    address_prefixes    = ["10.3.1.0/24"]
                }
                defaultsubnet ={
                    name                = "default"
                    address_prefixes    = ["10.3.2.0/24"]
                }
        }
    }

}
}

# declare Hub subnets
variable "hub_subnets" {
    type = map(object({
        name                = string
        address_prefixes    = list(string)
        isDefault           = bool
    }))

    default = {
        subnet1 = {
            name                = "AzureFirewallSubnet"
            address_prefixes    = ["10.1.1.0/24"]
            isDefault           = false
        }
        subnet2 = {
            name                = "AzureBastionSubnet"
            address_prefixes    = ["10.1.2.0/24"]
            isDefault           = false
        }
        subnet3 = {
            name = "default"
            address_prefixes    = ["10.1.3.0/24"]
            isDefault = true
        }
    }
}
# declare firewall rules
variable "nfirewall_rules" {
    type = map(object({
        collection_name         = string
        priority                = number
        action                  = string
        rule_name               = string
        source_addresses        = list(string)
        destination_ports       = list(string)
        destination_addresses   = list(string)
        protocols               = list(string)
    }))
    default = {
        rule1 = {
            collection_name         = "Default_Rule_Collection"
            priority                = 100
            action                  = "Allow"
            rule_name               = "intra_spoke"
            source_addresses        = ["10.2.2.0/24","10.3.2.0/24","10.1.0.0/16"]
            destination_ports       = ["*"]
            destination_addresses   = ["10.1.0.0/16","10.2.2.0/24","10.3.2.0/24"]
            protocols               = ["Any"]

        }
        rule2 = {
            collection_name         = "external_Rule_Collection"
            priority                = 200
            action                  = "Allow"
            rule_name               = "spokes_to_internet"
            source_addresses        = ["10.2.2.0/24","10.3.2.0/24","10.1.0.0/16"]
            destination_ports       = ["*"]
            destination_addresses   = ["*"]
            protocols               = ["TCP","UDP"]
        }
    }
}