output "id" {
  description = "ID of the Logic App workflow"
  value       = azurerm_logic_app_workflow.main.id
}

output "callback_url" {
  description = "HTTP trigger callback URL for the Logic App"
  value       = azurerm_logic_app_trigger_http_request.main.callback_url
  sensitive   = true
}
