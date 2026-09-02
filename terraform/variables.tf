# ==============================================================================
# Variables de Entrada - Terraform (CTF 2026)
# ==============================================================================

variable "environment" {
  description = "Entorno de despliegue (ej. prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos"
  type        = string
  default     = "eastus2"
}

variable "prefix" {
  description = "Prefijo identificador para todos los recursos del proyecto"
  type        = string
  default     = "ctf2026"
}

variable "vm_size" {
  description = "Tamaño de la máquina virtual (Standard_B2s acorde al presupuesto de $100 USD)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Nombre de usuario administrador de la máquina virtual"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceso a la VM. Si es null, se autogenera una clave TLS efímera."
  type        = string
  default     = null
}

variable "allowed_ssh_ips" {
  description = "Lista de bloques CIDR autorizados para conectarse vía SSH (puerto 22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "os_disk_size_gb" {
  description = "Tamaño en GB del disco de sistema operativo (StandardSSD_LRS)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Etiquetas comunes para seguimiento de costos y auditoría"
  type        = map(string)
  default = {
    Project     = "ChronosCTF-2026"
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "AzureForStudents-100USD"
  }
}
