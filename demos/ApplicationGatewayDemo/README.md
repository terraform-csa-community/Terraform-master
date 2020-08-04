#                                     Application Gateway Demo

This terraform module sets up the following Resources

**Resource Group**: AppGatewayDemo
**Virtual Network**: ApplicationVnet
- CIDR: 192.168.1.0/24
- AppGateway Subnet: 192.168.1.0/27
- Application Subnet: 192.168.1.128/25

**PublicIP**: AppGwyPIP1
**Application Gateway**: AppGateway1
**VMSS**: AppFarm

This will create a basic Application Gateway infrastructure that load balances VMSS nodes with a public facing IP address. This is an HTTP configuration with the Scale Set nodes configured with a basic static web page that presents the host name. This can be used as a building block to configure more complex App Gateway scenarios. 

**Additional Info**:
Application Gateway documentation - https://docs.microsoft.com/en-us/azure/application-gateway/overview

Connecting Terraform to your subscription - https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

Terraform Application Gateway documentation - https://www.terraform.io/docs/providers/azurerm/r/application_gateway.html

Author: Bryan Counts