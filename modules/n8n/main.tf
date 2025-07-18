# Common n8n deployment configuration
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Template for user data script
locals {
  user_data_script = templatefile("${path.module}/user-data.sh", {
    domain_name = var.domain_name
    subdomain   = var.subdomain
    ssl_email   = var.ssl_email
    timezone    = var.timezone
    db_password = var.db_password
  })
}

# Output the user data script for use by cloud-specific modules
output "user_data_script" {
  description = "User data script for VM initialization"
  value       = local.user_data_script
}

output "common_tags" {
  description = "Common tags for all resources"
  value       = local.common_tags
}