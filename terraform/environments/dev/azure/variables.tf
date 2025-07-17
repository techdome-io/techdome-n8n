# Variables for Azure development environment
variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key"
}

variable "allowed_ips" {
  type        = list(string)
  description = "Allowed IP addresses"
}

variable "os_disk_size" {
  type        = number
  description = "OS disk size in GB"
}

variable "os_disk_type" {
  type        = string
  description = "OS disk type"
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "Enable accelerated networking"
}

variable "domain_name" {
  type        = string
  description = "Domain name"
}

variable "subdomain" {
  type        = string
  description = "Subdomain"
}

variable "ssl_email" {
  type        = string
  description = "SSL email"
}

variable "timezone" {
  type        = string
  description = "Timezone"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}