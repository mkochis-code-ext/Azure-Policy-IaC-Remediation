output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.project.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.project.resource_group_id
}

output "nist_policy_assignment_id" {
  description = "ID of the NIST SP 800-53 Rev. 5 policy assignment"
  value       = module.project.nist_policy_assignment_id
}

output "nist_policy_assignment_name" {
  description = "Name of the NIST SP 800-53 Rev. 5 policy assignment"
  value       = module.project.nist_policy_assignment_name
}

output "nist_policy_principal_id" {
  description = "Principal ID of the managed identity for the NIST policy assignment"
  value       = module.project.nist_policy_principal_id
}

output "storage_name_policy_id" {
  description = "ID of the storage account name length custom policy assignment"
  value       = module.project.storage_name_policy_id
}

output "storage_name_policy_definition_id" {
  description = "ID of the storage account name length custom policy definition"
  value       = module.project.storage_name_policy_definition_id
}