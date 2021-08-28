output "always_on_listener_ip_address" {
    description = "Always On Listener IP Adddress"
    value = var.sqlInternalLB-ip
}
output "storage_account_name" {
    description = "Storage Account Name to be used as Cloud Witness (Cluster Quorum)"
    value = azurerm_storage_account.cloudwitness.name
}
output "storage_account_primary_access_key" {
    description = "Storage Account Primary Access Key - Admin to share"
    value = azurerm_storage_account.cloudwitness.primary_access_key
    sensitive = true
}
output "sql_health_probe_port" {
    description = "SQL Server Health Probe Port Number"
    value = azurerm_lb_probe.sqlLBProbe.port
}
