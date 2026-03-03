resource "azurerm_policy_definition" "main" {
  name         = var.policy_name
  policy_type  = "Custom"
  mode         = var.mode
  display_name = var.policy_display_name
  description  = var.policy_description

  metadata   = var.metadata
  parameters = var.parameters

  ## Use this structure with external .tftpl files for policy definitions.
  policy_rule = var.policy_rule
}

resource "azurerm_resource_group_policy_assignment" "main" {
  name                 = replace(substr(var.policy_name, 0, 24), " ", "-")
  display_name         = var.policy_display_name
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.main.id
  location             = var.location
  enforce              = !var.enforcement_mode

  parameters = var.assignment_parameters

  identity {
    type = "SystemAssigned"
  }

  metadata = jsonencode({
    assignedBy = "Terraform"
  })
}
