# Production environment configuration for AWS
project_name = "n8n"
environment  = "prod"

# AWS-specific settings
region            = "us-east-1"
availability_zone = "us-east-1a"
instance_type     = "t3.medium"  # Larger size for production
key_name          = "your-production-key-pair"  # Update with your AWS key pair name
root_volume_size  = 40
root_volume_type  = "gp3"
enable_monitoring = true  # Enable detailed monitoring for production
enable_eip        = true

# Network configuration
vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

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

# Tags
tags = {
  Environment = "prod"
  Project     = "n8n"
  Owner       = "DevOps Team"
  ManagedBy   = "Terraform"
  BackupRequired = "true"
}