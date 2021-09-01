resource "azurerm_eventhub_namespace" "example" {
  # Namespace name must be globally unique, 6-50 characters
  name                = "eventhub-namespace-${random_string.random.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  # A single throughput capacity unit lets you..
  # ingress: Up to 1 MB per second or 1000 events per second (whichever comes first). 
  # Egress: Up to 2 MB per second or 4096 events per second.
  capacity = 1

  # Auto-inflate can be enabled for scaling and set to a specific limit
  # https://azure.microsoft.com/en-us/blog/event-hubs-auto-inflate-take-control-of-your-scale/
  auto_inflate_enabled     = true
  maximum_throughput_units = 5
}

resource "azurerm_eventhub" "example" {
  name                = "eventhub"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  partition_count     = 1
  message_retention   = 1 # Retain events for x amount of days
}

// Grant access to our encryptioon function to send but not listen (receive) or manage the authorization rule
resource "azurerm_eventhub_authorization_rule" "function-encrypt" {
  name                = "function-encrypt"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.example.name
  listen              = false
  send                = true
  manage              = false
}

// Grant access to our decryption function to listen (receive) but not send or manage the authorization rule
resource "azurerm_eventhub_authorization_rule" "function-decrypt" {
  name                = "function-decrypt"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.example.name
  listen              = true
  send                = false
  manage              = false
}