output "topic_id" {
  description = "ID of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.main.id
}

output "subscription_id" {
  description = "ID of the Event Grid event subscription"
  value       = azurerm_eventgrid_system_topic_event_subscription.main.id
}
