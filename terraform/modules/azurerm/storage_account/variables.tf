variable "name" {
  description = "Name of the storage account (must be globally unique, 3-24 chars, lowercase letters and numbers only)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Storage replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind (StorageV2, BlobStorage, etc.)"
  type        = string
  default     = "StorageV2"
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account"
  type        = string
  default     = "TLS1_2"
}

variable "https_traffic_only_enabled" {
  description = "Whether only HTTPS traffic is allowed"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
