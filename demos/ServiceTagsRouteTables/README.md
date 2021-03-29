# Azure Route Table with Service Tags Demo

## Overview

This terraform code creates a route table with two routes, one using a traditional default route to an NVA, the other creates a route to an Azure Service Tag leveraging the new functionality announced [here](https://azure.microsoft.com/en-us/updates/public-preview-service-tags-for-user-defined-routing/).

The full list of available service tags can be found [here](https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview).