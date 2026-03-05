resource "azurerm_eventgrid_system_topic" "main" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = var.source_arm_resource_id
  topic_type             = var.topic_type
  location               = "global"
  tags                   = var.tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "main" {
  name                = var.event_subscription_name
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = var.resource_group_name

  webhook_endpoint {
    url = var.webhook_url
  }

  included_event_types = var.included_event_types
}
