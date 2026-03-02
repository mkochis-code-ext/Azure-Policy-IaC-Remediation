output "id" {
  description = "ID of the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.id
}

output "name" {
  description = "Name of the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.name
}

output "display_name" {
  description = "Display name of the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.display_name
}

output "principal_id" {
  description = "Principal ID of the managed identity created for the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.identity[0].principal_id
}
