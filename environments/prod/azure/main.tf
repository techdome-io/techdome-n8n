# Azure development environment main configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Common n8n module
module "n8n_common" {
  source = "../../../modules/n8n"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  subdomain    = var.subdomain
  ssl_email    = var.ssl_email
  timezone     = var.timezone
  vm_size      = var.vm_size
  ssh_public_key = var.ssh_public_key
  allowed_ips  = var.allowed_ips
  db_password  = var.db_password
  tags         = var.tags
}

# Azure VM module
module "azure_vm" {
  source = "../../../modules/azure-vm"

  project_name                  = var.project_name
  environment                   = var.environment
  location                      = var.location
  vm_size                       = var.vm_size
  admin_username                = var.admin_username
  ssh_public_key                = var.ssh_public_key
  allowed_ips                   = var.allowed_ips
  os_disk_size                  = var.os_disk_size
  os_disk_type                  = var.os_disk_type
  enable_accelerated_networking = var.enable_accelerated_networking
  user_data_script              = module.n8n_common.user_data_script
  tags                          = module.n8n_common.common_tags
}