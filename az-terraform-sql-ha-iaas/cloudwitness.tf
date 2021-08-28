resource "random_string" "accountname" {
  length = 6
  special = false
  upper = false
}
resource "azurerm_storage_account" "cloudwitness" {
  name                = substr(lower("sqlhacloudwitness${random_string.accountname.result}"),0,20)
  resource_group_name = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "GRS"
}
resource "azurerm_storage_container" "witness" {
  name                  = "sql-cloud-witness"
  storage_account_name  = azurerm_storage_account.cloudwitness.name
  container_access_type = "private"
}
resource "azurerm_storage_account_network_rules" "cloudwitness-networkrule" {
  resource_group_name  = var.resource_group
  storage_account_name = azurerm_storage_account.cloudwitness.name
  default_action             = "Allow"
  virtual_network_subnet_ids = ["${data.azurerm_subnet.dbsubnet.id}"]
  bypass                     = ["None"]
}
resource "azurerm_private_endpoint" "cloudwitness-endpoint" {
  name                = "sqlha${random_string.accountname.result}-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = "${data.azurerm_subnet.dbsubnet.id}"

  private_service_connection {
    name                           = "sqlha${random_string.accountname.result}-psc"
    private_connection_resource_id = azurerm_storage_account.cloudwitness.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
#Ensure that private-endpoint-network-policies is off
/*
az network vnet subnet update --name dbsubnet --resource-group sqlserverdemo --vnet-name network-1 --disable-private-endpoint-network-policies true
*/