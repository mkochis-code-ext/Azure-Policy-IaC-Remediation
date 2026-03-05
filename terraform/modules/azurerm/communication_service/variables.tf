variable "name" {
  description = "Base name for the communication service resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "data_location" {
  description = "Data location for Azure Communication Services (e.g., United States, Europe)"
  type        = string
  default     = "United States"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
