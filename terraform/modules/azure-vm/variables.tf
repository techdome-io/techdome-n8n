# Azure-specific variables for n8n deployment
variable "project_name" {
  type        = string
  description = "Name of the project for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
  default     = "East US"
}

variable "vm_size" {
  type        = string
  description = "Size of the Azure VM"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of IP addresses allowed to access the VM"
  default     = ["0.0.0.0/0"]
}

variable "user_data_script" {
  type        = string
  description = "User data script for VM initialization"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "os_disk_size" {
  type        = number
  description = "Size of the OS disk in GB"
  default     = 30
}

variable "os_disk_type" {
  type        = string
  description = "Type of the OS disk"
  default     = "Standard_LRS"
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "Enable accelerated networking"
  default     = false
}