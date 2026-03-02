variable "name" {
  description = "Display name for the policy assignment"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group to assign the policy initiative to"
  type        = string
}

variable "location" {
  description = "Azure region for the managed identity used by the policy assignment"
  type        = string
}

variable "policy_set_definition_id" {
  description = "ID of the policy set (initiative) definition to assign"
  type        = string
}

variable "enforcement_mode" {
  description = "Whether the policy assignment is enforced or only auditing. Defaults to false (enforce)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the policy assignment"
  type        = map(string)
  default     = {}
}
