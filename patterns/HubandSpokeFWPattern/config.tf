terraform {
  required_providers {
    azurerm = "~> 2.21"
  }
}

provider "azurerm" {
  subscription_id       = var.subscription_id
  client_id             = var.client_id
  client_secret         = var.client_secret
  tenant_id             = var.tenant_id
  features {}
}

# Create Resource Groups for hub and spoke resources
resource "azurerm_resource_group" "hubrg" {
    name            = "AzureFirewall_Hub_RG"
    location        = var.location
}

resource "azurerm_resource_group" "spokerg" {
    name            = "AzureFirewall_Spoke_RG"
    location        = var.location
}

# Create hub and spoke virtual networks

resource "azurerm_virtual_network" "hubvnet" {
    name                    = "AzureFirewall_Hub_vnet"
    address_space           = ["10.1.0.0/16"]
    resource_group_name     = azurerm_resource_group.hubrg.name
    location                = azurerm_resource_group.hubrg.location
}

resource "azurerm_virtual_network" "spokevnet" {
    for_each = var.spoke_networks

    name                    = "AzureFirewall_${each.value["name"]}_vnet"
    address_space           = each.value["address_space"]
    resource_group_name     = azurerm_resource_group.spokerg.name
    location                = azurerm_resource_group.spokerg.location

}

#create hub subnets 

resource "azurerm_subnet" "hubsubnet" {
    for_each = var.hub_subnets

    name                    = each.value["name"]
    address_prefixes        = each.value["address_prefixes"]
    virtual_network_name    = azurerm_virtual_network.hubvnet.name
    resource_group_name     = azurerm_resource_group.hubrg.name
}

## flatten spoke network objects

locals {
    spoke_subnets = flatten ([
        for network_key, network in var.spoke_networks : [
            for subnet_key, subnet in network.subnets : {
                network_key         = network_key
                subnet_key          = subnet_key
                network_id          = azurerm_virtual_network.spokevnet[network_key].id
                network_name        = azurerm_virtual_network.spokevnet[network_key].name
                address_prefixes    = subnet.address_prefixes 
                subnet_name         = subnet.name
                network_prefix      = network.prefix
            }
        ]
    ])
}

# create spoke subnets
resource "azurerm_subnet" "spokesubnet" {
    for_each = {
        for subnet in local.spoke_subnets : "${subnet.network_prefix}_${subnet.subnet_key}" => subnet
    }

    name                    = each.value.subnet_name
    address_prefixes        = each.value.address_prefixes
    virtual_network_name    = each.value.network_name
    resource_group_name     = azurerm_resource_group.spokerg.name

}

# VMs in each virtual network's default subnet

resource "azurerm_network_interface" "nic" {
    for_each = {
       for subnet in azurerm_subnet.spokesubnet : "${subnet.name}_${subnet.virtual_network_name}_nic" => subnet
       if subnet.name == "default"
    } 

    name = "${each.value["name"]}_${each.value["virtual_network_name"]}_nic" 
    location                = azurerm_resource_group.spokerg.location
    resource_group_name     = azurerm_resource_group.spokerg.name

    ip_configuration {
        name                = "internal"
        subnet_id           = each.value["id"]
        private_ip_address_allocation = "Dynamic"
    }
    tags                    = {
        virtualNetwork      = each.value["virtual_network_name"]
        subnet              = each.value["name"] 
    }

    depends_on = [azurerm_subnet.spokesubnet]
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = {
      for nic in azurerm_network_interface.nic : "${nic.name}_${nic.tags.virtualNetwork}" => nic

  }

  name                      = "testvm-${regex("[spoke]....\\d", each.value.tags["virtualNetwork"])}"
  resource_group_name       = azurerm_resource_group.spokerg.name
  location                  = azurerm_resource_group.spokerg.location
  size                      = "Standard_F2"
  admin_username            = "adminuser"
  admin_password            = "PasswordPassword123"
  network_interface_ids     = [each.value["id"]]

  os_disk {
    caching                 = "ReadWrite"
    storage_account_type    = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_network_interface.nic]
}

# Create azure firewall

resource "azurerm_public_ip" "firewall_pip" {
  name = "firewall-pip"
  resource_group_name   = azurerm_resource_group.hubrg.name
  location              = azurerm_resource_group.hubrg.location
  allocation_method     = "Static"
  sku                   = "Standard"
}

resource "azurerm_firewall" "firewall" {
for_each = {
    for hubsubnet in azurerm_subnet.hubsubnet : "${hubsubnet.name}_${hubsubnet.virtual_network_name}" => hubsubnet
    if hubsubnet.name == "AzureFirewallSubnet"
}
  name                          = "azure-firewall"
  resource_group_name           = azurerm_resource_group.hubrg.name
  location                      = azurerm_resource_group.hubrg.location
  ip_configuration {
    name                        = "hg_${azurerm_resource_group.hubrg.location}_azure_firewall_config"
    subnet_id                   = each.value["id"]
    public_ip_address_id        = azurerm_public_ip.firewall_pip.id
  }
   depends_on                   =[azurerm_public_ip.firewall_pip]

   tags = {
       virtualnetwork           = each.value["virtual_network_name"]
   }
}

# Create vnet peering
resource "azurerm_virtual_network_peering" "hub-spoke-peer" {
 for_each = {
     for spokes in azurerm_virtual_network.spokevnet : "${spokes.name}" => spokes
 }
  name                              = "${each.value["name"]}_to_${azurerm_virtual_network.hubvnet.name}_peer"
  resource_group_name               = each.value["resource_group_name"]
  virtual_network_name              = each.value["name"]
  remote_virtual_network_id         = azurerm_virtual_network.hubvnet.id
  allow_virtual_network_access      = true
  allow_forwarded_traffic           = true
  allow_gateway_transit             = false
  use_remote_gateways               = false
  depends_on                        = [azurerm_virtual_network.spokevnet, azurerm_virtual_network.hubvnet]
}

resource "azurerm_virtual_network_peering" "spoke-hub-peer" {
    for_each = {
        for spokes in azurerm_virtual_network.spokevnet :"${spokes.name}" => spokes

    }

    name                            = "${azurerm_virtual_network.hubvnet.name}_to_${each.value["name"]}_peer"
    resource_group_name             = azurerm_virtual_network.hubvnet.resource_group_name
    virtual_network_name            = azurerm_virtual_network.hubvnet.name
    remote_virtual_network_id       = each.value["id"]
    allow_virtual_network_access    = true 
    allow_forwarded_traffic         = true
    allow_gateway_transit           = false
    use_remote_gateways             = false
    depends_on                      = [azurerm_virtual_network.spokevnet, azurerm_virtual_network.hubvnet]
}

# create route table to force tunnel traffic to Firewall
resource "azurerm_route_table" "rt" {
for_each = {
    for firewall in azurerm_firewall.firewall : "AzureFirewallRoute_${firewall.tags.virtualnetwork}" => firewall

}
  name                          = "AzureFirewallRoute"
  location                      = azurerm_resource_group.spokerg.location
  resource_group_name           = azurerm_resource_group.spokerg.name
  disable_bgp_route_propagation = true

  route {
    name                    = "AZFroute"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "virtualAppliance"
    next_hop_in_ip_address  = each.value.ip_configuration[0]["private_ip_address"]
  }

  depends_on = [azurerm_firewall.firewall]
}

# Associate route table with spoke vnets

resource "azurerm_subnet_route_table_association" "rta" {
    for_each = {
        for spokesub in azurerm_subnet.spokesubnet : "${spokesub.name}_${spokesub.virtual_network_name}" => spokesub
        if spokesub.name == "default"
    }

    subnet_id           = each.value["id"]
    route_table_id      = azurerm_route_table.rt["AzureFirewallRoute_AzureFirewall_Hub_vnet"].id

    depends_on          = [azurerm_subnet.spokesubnet, azurerm_route_table.rt]
}

# create firewall rules

resource "azurerm_firewall_network_rule_collection" "fnrc" {
    for_each = var.nfirewall_rules

    name                    = each.value["collection_name"]
    azure_firewall_name     = azurerm_firewall.firewall["AzureFirewallSubnet_AzureFirewall_Hub_vnet"].name
    resource_group_name     = azurerm_resource_group.hubrg.name 
    priority                = each.value["priority"]
    action                  = each.value["action"]

    rule {
        name                    = each.value["rule_name"]
        source_addresses        = each.value["source_addresses"]
        destination_ports       = each.value["destination_ports"]
        destination_addresses   = each.value["destination_addresses"]
        protocols               = each.value["protocols"]
    }    
}