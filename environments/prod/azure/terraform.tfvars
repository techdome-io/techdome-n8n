# Production environment configuration for Azure
project_name = "n8n"
environment  = "prod"

# Azure-specific settings
location                      = "East US"
vm_size                      = "Standard_B4ms"  # Larger size for production
admin_username               = "azureuser"
os_disk_size                = 50
os_disk_type                = "Premium_LRS"     # Premium storage for production
enable_accelerated_networking = true

# n8n configuration
domain_name = "yourdomain.com"
subdomain   = "n8n"
ssl_email   = "admin@yourdomain.com"
timezone    = "Asia/Kolkata"

# Security - Restrict to specific IPs in production
allowed_ips = [
  "203.0.113.0/24",  # Replace with your office IP range
  "198.51.100.0/24"  # Replace with your home IP range
]

# Database
db_password = "your-very-secure-production-password"  # Use a strong password

# SSH Key (provide your public key here)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-production-public-key-here"

# Tags
tags = {
  Environment = "prod"
  Project     = "n8n"
  Owner       = "DevOps Team"
  ManagedBy   = "Terraform"
  BackupRequired = "true"
}