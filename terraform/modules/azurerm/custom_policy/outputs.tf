output "policy_definition_id" {
  description = "ID of the custom policy definition"
  value       = azurerm_policy_definition.main.id
}

output "policy_assignment_id" {
  description = "ID of the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.id
}

output "policy_assignment_name" {
  description = "Display name of the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.display_name
}

output "principal_id" {
  description = "Principal ID of the managed identity for the policy assignment"
  value       = azurerm_resource_group_policy_assignment.main.identity[0].principal_id
}
