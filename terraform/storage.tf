# ==============================================================================
# Almacenamiento Persistente para Respaldos (Azure Blob Storage)
# ==============================================================================

resource "azurerm_storage_account" "backups" {
  name                     = "stchronosctf${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  lifecycle {
    # Protege la cuenta de almacenamiento para que nunca sea eliminada por destroy o apply accidental
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backups.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Permisos para que la Identidad Administrada (MSI) de la VM pueda leer y escribir respaldos
resource "azurerm_role_assignment" "vm_storage_blob" {
  scope                = azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}
