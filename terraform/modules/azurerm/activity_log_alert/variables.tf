variable "name" {
  description = "Name of the activity log alert"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "scopes" {
  description = "List of resource IDs to scope the alert to"
  type        = list(string)
}

variable "description" {
  description = "Description of the alert"
  type        = string
  default     = ""
}

variable "action_group_id" {
  description = "ID of the action group to trigger"
  type        = string
}

variable "category" {
  description = "Activity log alert category (e.g., Policy, Administrative)"
  type        = string
}

variable "level" {
  description = "Alert level (e.g., Warning, Error, Informational)"
  type        = string
}

variable "operation_name" {
  description = "Operation name to filter on (e.g., Microsoft.Authorization/policies/audit/action)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the alert"
  type        = map(string)
  default     = {}
}
