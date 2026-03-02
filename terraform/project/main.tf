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
  max_name_length     = 10
  resource_type       = "Microsoft.Storage/storageAccounts"
  enforcement_mode    = var.policy_enforcement_disabled
  tags                = var.tags
}
