output "id" {
  description = "ID of the action group"
  value       = azurerm_monitor_action_group.main.id
}

output "name" {
  description = "Name of the action group"
  value       = azurerm_monitor_action_group.main.name
}
