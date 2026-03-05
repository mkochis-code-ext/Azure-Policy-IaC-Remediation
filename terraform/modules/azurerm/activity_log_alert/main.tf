resource "azurerm_monitor_activity_log_alert" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  description         = var.description
  tags                = var.tags

  criteria {
    category       = var.category
    level          = var.level
    operation_name = var.operation_name
  }

  action {
    action_group_id = var.action_group_id
  }
}
