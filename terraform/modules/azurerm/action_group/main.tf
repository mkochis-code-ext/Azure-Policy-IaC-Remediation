resource "azurerm_monitor_action_group" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = substr(var.short_name, 0, 12)
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}
