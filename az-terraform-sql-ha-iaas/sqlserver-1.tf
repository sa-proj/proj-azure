resource "azurerm_network_interface" "sqlserver-nic-1" {
  name                = "${var.sql-1-vm-name}-nic"
  resource_group_name = var.resource_group
  location            = var.location

  ip_configuration {
    name = "${var.sql-1-vm-name}-ipc1"
    private_ip_address_allocation = "static"
    subnet_id = "${data.azurerm_subnet.dbsubnet.id}"
    private_ip_address = var.sqlserver-1-ip
  }
}
resource "azurerm_windows_virtual_machine" "sql-1-vm" {
  name                = var.sql-1-vm-name
  resource_group_name   = var.resource_group
  location            = var.location
  zone                = 1
  size                = var.vm_size
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [azurerm_network_interface.sqlserver-nic-1.id]
  computer_name = var.sql-1-vm-name
  os_disk {
    name                 = "${var.sql-1-vm-name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.osdisksize
  }
  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2019"
    sku       = "enterprise"
    version   = "latest"
  }
}
resource "azurerm_managed_disk" "sql-1-vm-datadisk" {
  name                 = "${var.sql-1-vm-name}-datadisk"
  location             = var.location
  zones                = [1]
  resource_group_name  = var.resource_group
  storage_account_type = var.disk_type
  create_option        = "Empty"
  disk_size_gb         = var.datadisksize
}
resource "azurerm_virtual_machine_data_disk_attachment" "sql-1-vm-datadisk" {
  managed_disk_id    = azurerm_managed_disk.sql-1-vm-datadisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.sql-1-vm.id
  lun                = "10"
  caching            = "ReadWrite"
}
resource "azurerm_mssql_virtual_machine" "sqlvm-1" {
    virtual_machine_id               = azurerm_windows_virtual_machine.sql-1-vm.id
    sql_license_type                 = "AHUB"
    r_services_enabled               = false
    sql_connectivity_port            = 1433
    sql_connectivity_type            = "PRIVATE"
    sql_connectivity_update_username = var.sqladmin_user
    sql_connectivity_update_password = var.sqladmin_pass
    storage_configuration {
        disk_type               = "NEW"
        storage_workload_type   = "OLTP"
        data_settings {
            default_file_path = "X:\\DATA"
            luns = [azurerm_virtual_machine_data_disk_attachment.sql-1-vm-datadisk.lun]
        }

        log_settings {
            default_file_path = "X:\\LOG"
            luns = [azurerm_virtual_machine_data_disk_attachment.sql-1-vm-datadisk.lun]
        }

        temp_db_settings {
            default_file_path = "X:\\TEMPDB"
            luns = [azurerm_virtual_machine_data_disk_attachment.sql-1-vm-datadisk.lun]
        }

    }

}
resource "azurerm_virtual_machine_extension" "sql-1-prep" {
  depends_on=[azurerm_windows_virtual_machine.sql-1-vm]
  name = "${var.sql-1-vm-name}-vm-extension-prep"
  virtual_machine_id = azurerm_windows_virtual_machine.sql-1-vm.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"
  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./prepare-clusternode.ps1 -dnsIP ${var.dns_ipaddress}; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/pythianarora/total-practice/master/sample-sql-ha/prepare-clusternode.ps1"
        ]
    }
  SETTINGS
}