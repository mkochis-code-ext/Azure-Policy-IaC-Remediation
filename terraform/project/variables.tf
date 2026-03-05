variable "environment_prefix" {
  description = "Environment prefix"
  type        = string
}

variable "suffix" {
  description = "Random suffix for uniqueness"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "workload" {
  description = "Workload name"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "data_location" {
  description = "Azure region for data resources"
  type        = string
}

variable "policy_enforcement_disabled" {
  description = "Set to true to disable policy enforcement (audit-only mode)"
  type        = bool
  default     = true
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive policy compliance alerts"
  type        = list(string)
}
