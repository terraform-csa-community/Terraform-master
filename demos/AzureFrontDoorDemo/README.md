**

## Azure Front Door Demo
This terraform module creates the following resources in 2 regions: <br />
Virtual Network <br />
Resource Group <br />
Virtual Machine Scale Set <br />
Azure Load Balancer (Public Facing) <br />
Azure Front door <br />

The infrastructure can be visualized as such: <br />

![Diagram](https://github.com/bcounts1/AzureStuff/blob/master/content/images/AFDdemoDiagram.JPG) <br />
<br />
**
**Additional Info:**  <br />
Azure Front door Documentation - [https://docs.microsoft.com/en-us/azure/frontdoor/front-door-overview](https://docs.microsoft.com/en-us/azure/frontdoor/front-door-overview) <br />
Connecting Terraform to your subscription - [https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)<br />
Terraform Azure Front Door info - [https://www.terraform.io/docs/providers/azurerm/r/front_door.html](https://www.terraform.io/docs/providers/azurerm/r/front_door.html)<br />