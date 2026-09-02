# ==============================================================================
# Máquina Virtual Principal (Ubuntu 24.04 LTS) - CTFd & Retos
# ==============================================================================

# IP Pública para el servidor CTF
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-${var.prefix}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Tarjeta de Red (NIC)
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${var.prefix}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.platform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# Par de claves SSH generado automáticamente si no se proporciona ssh_public_key
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Máquina Virtual Linux (Standard_B2s, 30GB OS Disk)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key != null ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Configuración inicial mediante cloud-init
  custom_data = filebase64("${path.module}/../scripts/cloud-init.sh")

  identity {
    type = "SystemAssigned"
  }
}

# Asignación de rol AcrPull para que la VM pueda descargar imágenes de retos de forma segura
resource "azurerm_role_assignment" "vm_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}
