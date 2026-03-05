output "id" {
  description = "ID of the Azure Communication Service instance"
  value       = azurerm_communication_service.main.id
}

output "primary_connection_string" {
  description = "Primary connection string for the Communication Service"
  value       = azurerm_communication_service.main.primary_connection_string
  sensitive   = true
}

output "sender_email_address" {
  description = "The DoNotReply sender email address from the Azure-managed domain"
  value       = "DoNotReply@${azurerm_email_communication_service_domain.main.mail_from_sender_domain}"
}

output "email_domain_id" {
  description = "ID of the email communication service domain"
  value       = azurerm_email_communication_service_domain.main.id
}
