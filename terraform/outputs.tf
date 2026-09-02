# ==============================================================================
# Salidas de Infraestructura - Terraform (CTF 2026)
# ==============================================================================

output "resource_group_name" {
  description = "Nombre del Resource Group principal desplegado"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Dirección IP pública asignada a la máquina virtual"
  value       = azurerm_public_ip.vm_pip.ip_address
}

output "acr_login_server" {
  description = "Endpoint de inicio de sesión del Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Nombre del Azure Container Registry creado"
  value       = azurerm_container_registry.acr.name
}

output "ssh_connection_command" {
  description = "Comando rápido para conectarse por SSH al servidor"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.vm_pip.ip_address}"
}

output "tls_private_key" {
  description = "Clave privada SSH generada automáticamente (solo si no se especificó ssh_public_key)"
  value       = var.ssh_public_key == null ? tls_private_key.ssh[0].private_key_pem : null
  sensitive   = true
}
