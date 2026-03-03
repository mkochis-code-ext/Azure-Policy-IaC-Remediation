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

variable "mode" {
  description = "The policy mode (e.g., All, Indexed)"
  type        = string
  default     = "Indexed"
}

variable "metadata" {
  description = "JSON-encoded metadata for the policy definition"
  type        = string
  default     = null
}

variable "parameters" {
  description = "JSON-encoded parameters for the policy definition"
  type        = string
  default     = null
}

variable "policy_rule" {
  description = "The policy rule content, typically rendered via templatefile() from a .tftpl file"
  type        = string
}

variable "assignment_parameters" {
  description = "JSON-encoded parameters for the policy assignment"
  type        = string
  default     = null
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
