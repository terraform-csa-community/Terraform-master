## Hub and Spoke w/ Azure Firewall Mediation Pattern
This terraform module creates the following resources: <br />
3x Virtual Networks <br />
2x Resource Groups <br />
2x Virtual Machines <br />
2x Network Interfaces <br />
1x Azure Firewall <br />
2x Azure Firewall Rule collections <br />
1x Public IP address for Azure Firewall <br />
7x subnets <br />
1x route table  <br />
2x route table associations <br />
4x vnet peers <br /> 

The infrastructure can be visualized as such: <br />

![Diagram](https://github.com/bcounts1/AzureStuff/blob/master/content/images/HubAndSpokeFirewallPattern.jpeg) <br />
<br />

### Notes

This pattern invokes a common Hub and Spoke scenario wherein an organization wants to mediate all traffic between spokes with a firewall. On each spoke configured is a "0.0.0.0/0" user defined route which forces all traffic to the private interface of the azure firewall. The rules configured on the firewall allows all traffic on any of the spokes to access destinations in another spoke or within the hub itself. Any internet traffic is also routed through the firewall as well. A VM is deployed in each default spoke subnet to allow for testing traffic. an Azure Bastion subnet is also pre-created to give the option of using the service to interact with the hosts. 

**New Terraform Functionality**

This terraform makes use of the more recent additions to terraform, such as the "For_Each" loop, to dynamically construct resources. You can find out more on this here: <br />
[https://learn.hashicorp.com/tutorials/terraform/for-each](https://learn.hashicorp.com/tutorials/terraform/for-each)


**Additional Info:**  <br />
Azure Firewall Documentation - [https://docs.microsoft.com/en-us/azure/firewall/overview](https://docs.microsoft.com/en-us/azure/firewall/overview) <br />
Connecting Terraform to your subscription - [https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)<br />
Terraform Azure Firewall info - [https://www.terraform.io/docs/providers/azurerm/r/firewall.html](https://www.terraform.io/docs/providers/azurerm/r/firewall.html)<br />