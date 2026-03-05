terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
  }
}

resource "azurerm_email_communication_service" "main" {
  name                = "ecs-${var.name}"
  resource_group_name = var.resource_group_name
  data_location       = var.data_location
  tags                = var.tags
}

resource "azurerm_email_communication_service_domain" "main" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.main.id
  domain_management = "AzureManaged"
}

resource "azurerm_communication_service" "main" {
  name                = "acs-${var.name}"
  resource_group_name = var.resource_group_name
  data_location       = var.data_location
  tags                = var.tags
}

resource "azapi_update_resource" "domain_link" {
  type        = "Microsoft.Communication/communicationServices@2023-04-01"
  resource_id = azurerm_communication_service.main.id

  body = jsonencode({
    properties = {
      linkedDomains = [azurerm_email_communication_service_domain.main.id]
    }
  })
}
