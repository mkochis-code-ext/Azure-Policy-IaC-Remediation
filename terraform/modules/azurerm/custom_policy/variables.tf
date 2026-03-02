variable "policy_name" {
  description = "Name for the custom policy definition"
  type        = string
}

variable "policy_display_name" {
  description = "Display name for the custom policy definition"
  type        = string
}

variable "policy_description" {
  description = "Description of the custom policy"
  type        = string
  default     = ""
}

variable "resource_group_id" {
  description = "ID of the resource group to assign the policy to"
  type        = string
}

variable "location" {
  description = "Azure region for the managed identity"
  type        = string
}

variable "max_name_length" {
  description = "Maximum allowed length for resource names"
  type        = number
}

variable "resource_type" {
  description = "The Azure resource type to scope the policy to (e.g., Microsoft.Storage/storageAccounts)"
  type        = string
}

variable "enforcement_mode" {
  description = "Set to true to disable enforcement (audit-only). Defaults to false (enforced)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the policy assignment"
  type        = map(string)
  default     = {}
}
