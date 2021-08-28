#Create the SQL Load Balancer for AG
resource "azurerm_lb" "sqlinternalLB" {
  name                = var.load-balancer-name
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "Standard"
  depends_on          = [azurerm_virtual_machine_extension.sql-1-prep, azurerm_virtual_machine_extension.sql-2-prep]
  frontend_ip_configuration {
    name                          =  "${var.load-balancer-name}-fipc"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.sqlInternalLB-ip
    subnet_id                     = "${data.azurerm_subnet.dbsubnet.id}"
  }
}

#Create the load balencer backend pool
resource "azurerm_lb_backend_address_pool" "sqlLBBE" {
  loadbalancer_id     = azurerm_lb.sqlinternalLB.id
  name                = "${var.load-balancer-name}-backendpool"
}

#Add the first VM to the load balencer
resource "azurerm_network_interface_backend_address_pool_association" "sqlvm1BEAssoc" {
  network_interface_id    = azurerm_network_interface.sqlserver-nic-1.id
  ip_configuration_name   = "${var.sql-1-vm-name}-ipc1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlLBBE.id
}

#Add the second VM to the load balencer
resource "azurerm_network_interface_backend_address_pool_association" "sqlvm2BEAssoc" {
  network_interface_id    = azurerm_network_interface.sqlserver-nic-2.id
  ip_configuration_name   = "${var.sql-2-vm-name}-ipc1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.sqlLBBE.id
}

#Create the load balencer rules
#rule to connect to listener on default port
resource "azurerm_lb_rule" "sqlLBRule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = "${azurerm_lb.sqlinternalLB.id}"
  name                           = "${var.load-balancer-name}-lbr"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "${var.load-balancer-name}-fipc"
  probe_id                       = "${azurerm_lb_probe.sqlLBProbe.id}"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.sqlLBBE.id
  enable_floating_ip             = true
}
#rule to connect to listener on port 5022 required for distributed ag
#if this non distributed AG setup then you can remove this rule 
resource "azurerm_lb_rule" "sqlLBHAEndpointRule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = "${azurerm_lb.sqlinternalLB.id}"
  name                           = "${var.load-balancer-name}-lbr"
  protocol                       = "Tcp"
  frontend_port                  = 5022
  backend_port                   = 5022
  frontend_ip_configuration_name = "${var.load-balancer-name}-fipc"
  probe_id                       = "${azurerm_lb_probe.sqlLBProbe.id}"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.sqlLBBE.id
  enable_floating_ip             = true
}
#Create a health probe for the load balencer
resource "azurerm_lb_probe" "sqlLBProbe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = "${azurerm_lb.sqlinternalLB.id}"
  name                = "${var.load-balancer-name}-SQLAOProbe"
  port                = 59999
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}