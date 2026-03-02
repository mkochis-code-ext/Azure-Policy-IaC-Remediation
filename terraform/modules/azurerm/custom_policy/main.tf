resource "azurerm_policy_definition" "main" {
  name         = var.policy_name
  display_name = var.policy_display_name
  description  = var.policy_description
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({
    category = "Naming"
  })

  parameters = jsonencode({
    maxNameLength = {
      type = "Integer"
      metadata = {
        displayName = "Maximum resource name length"
        description = "The maximum number of characters allowed in the resource name"
      }
    }
    resourceType = {
      type = "String"
      metadata = {
        displayName = "Resource type"
        description = "The Azure resource type to enforce the naming rule on"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "[parameters('resourceType')]"
        },
        {
          value  = "[greater(length(field('name')), parameters('maxNameLength'))]"
          equals = true
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "main" {
  name                 = replace(substr(var.policy_name, 0, 24), " ", "-")
  display_name         = var.policy_display_name
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.main.id
  location             = var.location
  enforce              = !var.enforcement_mode

  parameters = jsonencode({
    maxNameLength = {
      value = var.max_name_length
    }
    resourceType = {
      value = var.resource_type
    }
  })

  identity {
    type = "SystemAssigned"
  }

  metadata = jsonencode({
    assignedBy = "Terraform"
  })
}
