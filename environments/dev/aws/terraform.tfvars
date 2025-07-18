# Development environment configuration for AWS
project_name = "n8n"
environment  = "dev"

# AWS-specific settings
region            = "us-east-1"
availability_zone = "us-east-1a"
instance_type     = "t3.small"
key_name          = "your-key-pair-name"  # Update with your AWS key pair name
root_volume_size  = 20
root_volume_type  = "gp3"
enable_monitoring = false
enable_eip        = true

# Network configuration
vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

# n8n configuration
domain_name = "example.com"
subdomain   = "n8n-dev"
ssl_email   = "admin@example.com"
timezone    = "Asia/Kolkata"

# Security
allowed_ips = [
  "0.0.0.0/0"  # Update with your IP address for better security
]

# Database
db_password = "your-secure-password-here"  # Update with secure password

# Tags
tags = {
  Environment = "dev"
  Project     = "n8n"
  Owner       = "DevOps Team"
  ManagedBy   = "Terraform"
}