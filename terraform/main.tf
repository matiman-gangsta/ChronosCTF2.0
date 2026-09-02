# ==============================================================================
# Infraestructura Base: Resource Group, Red Virtual y Seguridad de Red (NSG)
# ==============================================================================

# Resource Group Principal
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Red Virtual (VNet)
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.prefix}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subred 1: Plataforma (CTFd, Nginx, Redis, DB local)
resource "azurerm_subnet" "platform" {
  name                 = "snet-platform"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subred 2: Retos y Desafíos Contenedorizados
resource "azurerm_subnet" "challenges" {
  name                 = "snet-challenges"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group (NSG) con reglas estrictas
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.prefix}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Regla 1: Tráfico Web Seguro (HTTPS)
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regla 2: Tráfico Web Estándar (HTTP)
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regla 3: Administración SSH (Restringido vía variable allowed_ssh_ips)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ssh_ips
    destination_address_prefix = "*"
  }

  # Regla 4: Rango para Retos expuestos directamente (ej. pwn / netcat / tcp)
  security_rule {
    name                       = "Allow-CTF-Challenge-Ports"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000-8100"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociación de NSG a la Subred de Plataforma
resource "azurerm_subnet_network_security_group_association" "platform" {
  subnet_id                 = azurerm_subnet.platform.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Asociación de NSG a la Subred de Retos
resource "azurerm_subnet_network_security_group_association" "challenges" {
  subnet_id                 = azurerm_subnet.challenges.id
  network_security_group_id = azurerm_network_security_group.main.id
}
