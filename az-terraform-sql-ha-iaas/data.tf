data "azurerm_subnet" "dbsubnet" {
  name                 =  var.subnet_name
  virtual_network_name =  var.vnet_name
  resource_group_name  =  var.resource_group
}
data "azurerm_network_security_group" "sqlhagrp" {
  name                 =  var.nsg_name
  resource_group_name  =  var.resource_group
}