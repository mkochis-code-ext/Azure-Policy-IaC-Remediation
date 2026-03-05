locals {
  resource_group_name  = "rg-${var.workload}-${var.environment_prefix}-${var.suffix}"
  storage_account_name = substr(lower("st${var.workload}${var.environment_prefix}${var.suffix}"), 0, 24)
  actual_data_location = var.data_location != "" ? var.data_location : var.location

  # NIST SP 800-53 Rev. 5 built-in initiative definition ID
  nist_sp_800_53_r5_initiative_id = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
}

# Resource Group
module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# NIST SP 800-53 Rev. 5 Policy Initiative Assignment
module "nist_sp_800_53_r5_policy" {
  source = "../modules/azurerm/policy_assignment"

  name                    = "NIST SP 800-53 R5"
  resource_group_id       = module.resource_group.id
  location                = var.location
  policy_set_definition_id = local.nist_sp_800_53_r5_initiative_id
  enforcement_mode        = var.policy_enforcement_disabled
  tags                    = var.tags
}

# Storage Account
module "storage_account" {
  source = "../modules/azurerm/storage_account"

  name                = replace(local.storage_account_name, "-", "")
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = var.tags
}

# Custom Policy - Storage Account Name Max Length
module "storage_name_length_policy" {
  source = "../modules/azurerm/custom_policy"

  policy_name         = "Custom-storage-name-max-length"
  policy_display_name = "Storage account name must not exceed 10 characters"
  policy_description  = "Denies creation of storage accounts whose name exceeds 10 characters."
  resource_group_id   = module.resource_group.id
  location            = var.location
  enforcement_mode    = var.policy_enforcement_disabled
  tags                = var.tags

  metadata = jsonencode({
    category = "Naming"
  })

  ## Use this structure with external .tftpl files for policy definitions.
  policy_rule = templatefile("${path.module}/../policy_content/storage_name_max_length.tftpl", {
    resource_type  = "Microsoft.Storage/storageAccounts"
    max_name_length = 10
  })

  assignment_parameters = jsonencode({
    # No assignment-level parameters needed; values are baked into the policy rule via templatefile
  })
}

# Policy Compliance Email Alerts
# ─────────────────────────────────────────────────────────────────────────────
# Action Group: shared email notification target for policy alerts
# ─────────────────────────────────────────────────────────────────────────────

module "policy_action_group" {
  source = "../modules/azurerm/action_group"

  name                = "ag-${var.workload}-${var.environment_prefix}-policy"
  resource_group_name = module.resource_group.name
  short_name          = "pol-alerts"
  email_addresses     = var.alert_email_addresses
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Activity Log Alerts: real-time policy audit and deny events (Custom Policy)
# ─────────────────────────────────────────────────────────────────────────────

module "policy_audit_alert" {
  source = "../modules/azurerm/activity_log_alert"

  name                = "alert-${var.workload}-${var.environment_prefix}-policy-noncompliant"
  resource_group_name = module.resource_group.name
  scopes              = [module.resource_group.id]
  description         = "Alert when a policy compliance state changes to non-compliant"
  action_group_id     = module.policy_action_group.id
  category            = "Policy"
  level               = "Warning"
  operation_name      = "Microsoft.Authorization/policies/audit/action"
  tags                = var.tags
}

module "policy_deny_alert" {
  source = "../modules/azurerm/activity_log_alert"

  name                = "alert-${var.workload}-${var.environment_prefix}-policy-deny"
  resource_group_name = module.resource_group.name
  scopes              = [module.resource_group.id]
  description         = "Alert when a policy denies a resource operation"
  action_group_id     = module.policy_action_group.id
  category            = "Policy"
  level               = "Error"
  operation_name      = "Microsoft.Authorization/policies/deny/action"
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Azure Communication Services: email provider for Event Grid alerts
# ─────────────────────────────────────────────────────────────────────────────

module "communication_service" {
  source = "../modules/azurerm/communication_service"

  name                = "${var.workload}-${var.environment_prefix}"
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Logic App: sends NIST compliance emails via ACS
# ─────────────────────────────────────────────────────────────────────────────

module "nist_compliance_logic_app" {
  source = "../modules/azurerm/logic_app_email"

  name                      = "logic-${var.workload}-${var.environment_prefix}-nist-compliance"
  resource_group_name       = module.resource_group.name
  location                  = var.location
  acs_connection_string     = module.communication_service.primary_connection_string
  sender_email_address      = module.communication_service.sender_email_address
  recipient_email_addresses = var.alert_email_addresses
  email_subject             = "NIST SP 800-53 R5 - Policy Compliance State Change"
  email_body_html           = "<h2>NIST SP 800-53 Rev. 5 Policy Compliance Alert</h2><p>A policy compliance state change was detected.</p><p><strong>Event Details:</strong></p><pre>@{triggerBody()}</pre>"
  tags                      = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Event Grid: subscription-level policy state change events → Logic App
# ─────────────────────────────────────────────────────────────────────────────

data "azurerm_subscription" "current" {}

module "nist_eventgrid_topic" {
  source = "../modules/azurerm/eventgrid_system_topic"

  name                    = "evgt-${var.workload}-${var.environment_prefix}-policy-insights"
  resource_group_name     = module.resource_group.name
  source_arm_resource_id  = data.azurerm_subscription.current.id
  topic_type              = "Microsoft.PolicyInsights.PolicyStates"
  event_subscription_name = "evgs-${var.workload}-${var.environment_prefix}-nist-compliance"
  webhook_url             = module.nist_compliance_logic_app.callback_url
  tags                    = var.tags

  included_event_types = [
    "Microsoft.PolicyInsights.PolicyStateChanged",
    "Microsoft.PolicyInsights.PolicyStateCreated",
    "Microsoft.PolicyInsights.PolicyStateDeleted"
  ]
}
