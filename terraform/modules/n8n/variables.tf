# Common variables for n8n module
variable "project_name" {
  type        = string
  description = "Name of the project for resource naming"
  default     = "n8n"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
  default     = "dev"
}

variable "domain_name" {
  type        = string
  description = "Domain name for n8n deployment"
}

variable "subdomain" {
  type        = string
  description = "Subdomain for n8n deployment"
  default     = "n8n"
}

variable "ssl_email" {
  type        = string
  description = "Email for SSL certificate generation"
}

variable "timezone" {
  type        = string
  description = "Timezone for n8n deployment"
  default     = "Asia/Kolkata"
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
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

variable "db_password" {
  type        = string
  description = "Password for PostgreSQL database"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}