variable "name" {
  description = "Name of the Event Grid system topic"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create the topic in"
  type        = string
}

variable "source_arm_resource_id" {
  description = "ARM resource ID of the event source (e.g., subscription ID)"
  type        = string
}

variable "topic_type" {
  description = "Event Grid topic type (e.g., Microsoft.PolicyInsights.PolicyStates)"
  type        = string
}

variable "event_subscription_name" {
  description = "Name of the event subscription"
  type        = string
}

variable "webhook_url" {
  description = "Webhook endpoint URL to deliver events to"
  type        = string
  sensitive   = true
}

variable "included_event_types" {
  description = "List of event types to subscribe to"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the system topic"
  type        = map(string)
  default     = {}
}
