output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "nist_policy_assignment_id" {
  description = "ID of the NIST SP 800-53 Rev. 5 policy assignment"
  value       = module.nist_sp_800_53_r5_policy.id
}

output "nist_policy_assignment_name" {
  description = "Name of the NIST SP 800-53 Rev. 5 policy assignment"
  value       = module.nist_sp_800_53_r5_policy.display_name
}

output "nist_policy_principal_id" {
  description = "Principal ID of the managed identity for the NIST policy assignment"
  value       = module.nist_sp_800_53_r5_policy.principal_id
}

output "storage_name_policy_id" {
  description = "ID of the storage account name length custom policy assignment"
  value       = module.storage_name_length_policy.policy_assignment_id
}

output "storage_name_policy_definition_id" {
  description = "ID of the storage account name length custom policy definition"
  value       = module.storage_name_length_policy.policy_definition_id
}