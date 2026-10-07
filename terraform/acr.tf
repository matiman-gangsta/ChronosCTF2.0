# ==============================================================================
# Azure Container Registry (ACR) - Deshabilitado para optimizar costos ($0 extra)
# Los retos se compilan y administran directamente en el Docker de la VM
# ==============================================================================

# resource "azurerm_container_registry" "acr" {
#   name                = replace(lower("${var.prefix}${var.environment}acr"), "/[^a-z0-9]/", "")
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   sku                 = "Basic"
#   admin_enabled       = true
# 
#   tags = var.tags
# }

