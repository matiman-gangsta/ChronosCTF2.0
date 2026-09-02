# ==============================================================================
# Terraform Remote State Backend - Azure Blob Storage
# ==============================================================================
# Antes de habilitar este bloque, crea la cuenta de almacenamiento en Azure CLI:
#   az group create --name rg-ctf-tfstate --location eastus2
#   az storage account create --name stctf2026tfstate --resource-group rg-ctf-tfstate --sku Standard_LRS --encryption-services blob
#   az storage container create --name tfstate --account-name stctf2026tfstate
# ==============================================================================

terraform {
  backend "azurerm" {
    # resource_group_name  = "rg-ctf-tfstate"
    # storage_account_name = "stctf2026tfstate"
    # container_name       = "tfstate"
    # key                  = "prod.terraform.tfstate"
    # use_oidc             = true
  }
}
