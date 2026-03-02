data "azurerm_policy_set_definition" "initiative" {
  display_name = null
  name         = regex("[^/]+$", var.policy_set_definition_id)
}

resource "azurerm_resource_group_policy_assignment" "main" {
  name                 = replace(substr(var.name, 0, 24), " ", "-")
  display_name         = var.name
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_set_definition.initiative.id
  location             = var.location
  not_scopes           = []
  enforce              = !var.enforcement_mode

  identity {
    type = "SystemAssigned"
  }

  metadata = jsonencode({
    assignedBy = "Terraform"
  })
}
