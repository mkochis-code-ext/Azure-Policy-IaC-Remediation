data "azurerm_managed_api" "acsemail" {
  name     = "acsemail"
  location = var.location
}

resource "azurerm_api_connection" "acsemail" {
  name                = "api-acsemail-${var.name}"
  resource_group_name = var.resource_group_name
  managed_api_id      = data.azurerm_managed_api.acsemail.id
  display_name        = "ACS Email - ${var.name}"
  tags                = var.tags

  parameter_values = {
    api_key = var.acs_connection_string
  }
}

resource "azurerm_logic_app_workflow" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  parameters = {
    "$connections" = jsonencode({
      acsemail = {
        connectionId   = azurerm_api_connection.acsemail.id
        connectionName = azurerm_api_connection.acsemail.name
        id             = data.azurerm_managed_api.acsemail.id
      }
    })
  }
}

resource "azurerm_logic_app_trigger_http_request" "main" {
  name         = "on_event"
  logic_app_id = azurerm_logic_app_workflow.main.id

  schema = jsonencode({
    type = "array"
    items = {
      type = "object"
      properties = {
        id        = { type = "string" }
        topic     = { type = "string" }
        subject   = { type = "string" }
        eventType = { type = "string" }
        eventTime = { type = "string" }
        data      = { type = "object" }
      }
    }
  })
}

locals {
  email_recipients = [for email in var.recipient_email_addresses : { address = email, displayName = email }]
}

resource "azurerm_logic_app_action_custom" "send_email" {
  name         = "Send_alert_email"
  logic_app_id = azurerm_logic_app_workflow.main.id

  body = jsonencode({
    type     = "ApiConnection"
    runAfter = {}
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['acsemail']['connectionId']"
        }
      }
      method = "post"
      path   = "/emails:send"
      queries = {
        "api-version" = "2023-03-31"
      }
      body = {
        senderAddress = var.sender_email_address
        content = {
          subject = var.email_subject
          html    = var.email_body_html
        }
        recipients = {
          to = local.email_recipients
        }
      }
    }
  })
}
