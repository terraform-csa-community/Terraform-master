
provider "azurerm" {
  version = "=2.21.0"
  features {}
}

resource "azurerm_resource_group" "private-k8s" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet_cluster" {
  name                = "vnet-private-aks-demo"
  location            = var.location
  resource_group_name = azurerm_resource_group.private-k8s.name
  address_space       = ["10.1.0.0/16"]
}
resource "azurerm_subnet" "snet_cluster" {
  name                 = "snet-private-aks-demo"
  resource_group_name  = azurerm_resource_group.private-k8s.name
  virtual_network_name = azurerm_virtual_network.vnet_cluster.name
  address_prefixes     = ["10.1.0.0/24"]
  # Enforce network policies to allow Private Endpoint to be added to the subnet
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_kubernetes_cluster" "private_aks" {
  name                = "demo-private-aks-cluster"
  location            = var.location
  resource_group_name = azurerm_resource_group.private-k8s.name
  dns_prefix          = "aks-cluster"
  # Private Cluster
  private_cluster_enabled = true

  role_based_access_control {
    enabled = true
  }
  # Enable Kubernetes Dashboard, if needed
  addon_profile {
    kube_dashboard {
      enabled = true
    }
  }
  # To prevent CIDR collition with the 10.0.0.0/16 Vnet
  network_profile {
    network_plugin     = "kubenet"
    docker_bridge_cidr = "192.167.0.1/16"
    dns_service_ip     = "192.168.1.1"
    service_cidr       = "192.168.0.0/16"
    pod_cidr           = "172.16.0.0/22"
  }

  default_node_pool {
    name           = "agentpool"
    node_count     = var.agent_count
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.snet_cluster.id
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
}