variable "environment_prefix" {
  description = "Environment prefix (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "workload" {
  description = "Workload name"
  type        = string
  default     = "terraform-sample"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "data_location" {
  description = "Azure region for data resources (defaults to location if not specified)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "Terraform Sample"
    Owner      = "Platform Team"
    CostCenter = "Engineering"
  }
}

variable "policy_enforcement_disabled" {
  description = "Set to true to disable policy enforcement (audit-only mode)"
  type        = bool
  default     = false
}
