resource "azurerm_network_interface_security_group_association" "sqlhagrpAsso-sql1" {
  network_interface_id      = azurerm_network_interface.sqlserver-nic-1.id
  network_security_group_id = data.azurerm_network_security_group.sqlhagrp.id
}

resource "azurerm_network_interface_security_group_association" "sqlhagrpAsso-sql2" {
  network_interface_id      = azurerm_network_interface.sqlserver-nic-2.id
  network_security_group_id = data.azurerm_network_security_group.sqlhagrp.id
}