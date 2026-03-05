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

output "policy_alert_action_group_id" {
  description = "ID of the policy alerts action group"
  value       = module.policy_action_group.id
}

output "policy_audit_alert_id" {
  description = "ID of the policy audit activity log alert"
  value       = module.policy_audit_alert.id
}

output "policy_deny_alert_id" {
  description = "ID of the policy deny activity log alert"
  value       = module.policy_deny_alert.id
}

output "communication_service_id" {
  description = "ID of the Azure Communication Service instance"
  value       = module.communication_service.id
}

output "nist_logic_app_id" {
  description = "ID of the NIST compliance Logic App"
  value       = module.nist_compliance_logic_app.id
}

output "nist_eventgrid_topic_id" {
  description = "ID of the NIST compliance Event Grid system topic"
  value       = module.nist_eventgrid_topic.topic_id
}