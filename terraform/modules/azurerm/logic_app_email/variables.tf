variable "name" {
  description = "Name of the Logic App workflow"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Logic App and API connection"
  type        = string
}

variable "acs_connection_string" {
  description = "Primary connection string for Azure Communication Services"
  type        = string
  sensitive   = true
}

variable "sender_email_address" {
  description = "Sender email address from the ACS managed domain"
  type        = string
}

variable "recipient_email_addresses" {
  description = "List of email addresses to receive alert emails"
  type        = list(string)
}

variable "email_subject" {
  description = "Subject line for the alert email"
  type        = string
}

variable "email_body_html" {
  description = "HTML body for the alert email. Use @{triggerBody()} to include event data."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
