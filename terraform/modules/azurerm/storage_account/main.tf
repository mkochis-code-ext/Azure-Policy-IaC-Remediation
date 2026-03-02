resource "azurerm_storage_account" "main" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  account_tier               = var.account_tier
  account_replication_type   = var.account_replication_type
  account_kind               = var.account_kind
  min_tls_version            = var.min_tls_version
  https_traffic_only_enabled = var.https_traffic_only_enabled
  shared_access_key_enabled  = false
  tags                       = var.tags
}
