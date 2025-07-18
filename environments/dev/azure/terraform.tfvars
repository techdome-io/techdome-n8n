# Development environment configuration for Azure
project_name = "n8n"
environment  = "dev"

# Azure-specific settings
location                      = "East US"
vm_size                      = "Standard_B2s"
admin_username               = "azureuser"
os_disk_size                = 30
os_disk_type                = "Standard_LRS"
enable_accelerated_networking = false


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
db_password = "n8npassn8npass"

# SSH Key (provide your public key here)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4XXpLWJajNDgCFkOjCYICTMB6VO3RGrNItdZudjGJ0NyMUzGx0f0/trcxXZfiWzCc6QDUx2D7Aav7YCmIfnFBnKc5spkEue4q7K4z8O3hiIxfQQPtti87tAJE6ox/zn8PXEGZq6XdDSMH4hUeEnX9D/trpqN2+soj3N04R6O1o9KhPzguwjUW27fnExGNQJ8cC/+JC5A7rJVIPMwBzM/YlSxDLeK8d6UA0T2NRs1QwrU8KYTAG2EXnUv5dIQXMUkFKK1fjgiVCXzIAiWf4pUxdkWW4pFx3dX2pi3D17TQynPA+1bdzofgBm/g86EGO2Sasb5knwHgDcsGbQeOY7Fb45oDVShzoiKJcr2hZ3QdQ8sI9Qfj06lNuH7L9zkQ1WsSDXAvYGd1+CcmjK8WW3NX/nAIPSuhDei+AkTJZmJHnNn4Q60qn4YAxzgx0heK1lwqCBp59OYiFwaFUpKcHvbZQCSeOODApbUcM4SYQLCHWMj5TxfLp3+88oeWsRvkItbn+Cok1AvaZO7SKgj1+sCfla6RF5MTBragiKhFxSwkE+oY4i+iUOvLl/aDYka75C0IxNCIN64wSZsIjEeuVcP7APJhilKXSBkiuOJXC4bHSVyBrdHPaJdWkKSLcY0NCat1FWhhH1ekkmshEDsb/F5qn2zx6kPjRpJtokda7ZlXFQ== punit@punit"

# Tags
tags = {
  Environment = "dev"
  Project     = "n8n"
  Owner       = "DevOps Team"
  ManagedBy   = "Terraform"
}
