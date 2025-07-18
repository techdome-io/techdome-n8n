# n8n Terraform Deployment - Usage Examples

This document provides examples of how to use the enhanced interactive deployment script.

## Interactive Mode (Recommended)

### Basic Interactive Deployment

Simply run the script without any arguments for the full interactive experience:

```bash
./deploy.sh
```

The script will guide you through:
1. **Cloud Provider Selection**: Choose between Azure or AWS
2. **Environment Selection**: Choose between dev or prod
3. **n8n Configuration**: Set up domain, email, timezone, and database password
4. **Cloud-Specific Setup**: SSH keys for Azure or EC2 key pairs for AWS
5. **Action Selection**: Plan, Apply, or Destroy

### Example Interactive Session

```
===============================================
          n8n Terraform Deployment
===============================================

This script will help you deploy n8n on Azure or AWS using Terraform.
You can modify VM/instance configurations by editing the terraform.tfvars file.

===============================================
          Cloud Provider Selection
===============================================

Available cloud providers:
1. Azure (Azure Virtual Machines)
2. AWS (Amazon EC2)

[QUESTION] Select cloud provider (1 for Azure, 2 for AWS): 1
[INFO] Selected: Azure

===============================================
          Environment Selection
===============================================

Available environments:
1. Development (dev) - Smaller instances, basic storage
2. Production (prod) - Larger instances, premium storage, restricted access

[QUESTION] Select environment (1 for dev, 2 for prod): 1
[INFO] Selected: Development

===============================================
          n8n Configuration Setup
===============================================

[QUESTION] Enter your domain name (e.g., example.com): mydomain.com
[QUESTION] Enter subdomain for n8n (default: n8n): automation
[QUESTION] Enter your email for SSL certificate (e.g., admin@example.com): admin@mydomain.com
[QUESTION] Enter timezone (default: Asia/Kolkata): America/New_York
[QUESTION] Enter a secure password for the PostgreSQL database: [hidden]
[QUESTION] Confirm the database password: [hidden]

Configuration Summary:
Domain: automation.mydomain.com
Email: admin@mydomain.com
Timezone: America/New_York
n8n URL: https://automation.mydomain.com

===============================================
          Azure Configuration
===============================================

For Azure VM access, you need an SSH key pair.
[QUESTION] Do you have an SSH key pair ready? (y/N): N
[INFO] Generating SSH key pair...
[QUESTION] Enter a name for your SSH key (default: azure_n8n_key): 
[INFO] SSH key pair generated: /home/user/.ssh/azure_n8n_key
[INFO] SSH public key configured successfully

===============================================
          Action Selection
===============================================

Available actions:
1. Plan - Show what will be created/changed (safe, no changes made)
2. Apply - Create/update the infrastructure
3. Destroy - Remove all created infrastructure

[QUESTION] Select action (1 for plan, 2 for apply, 3 for destroy): 2
[INFO] Selected: Apply
```

## Non-Interactive Mode

For automation and CI/CD pipelines, use the non-interactive mode:

```bash
./deploy.sh --non-interactive -c azure -e dev -a plan
./deploy.sh --non-interactive -c aws -e prod -a apply
./deploy.sh --non-interactive -c azure -e dev -a destroy
```

**Note**: In non-interactive mode, you must manually update the terraform.tfvars file with your configuration before running the script.

## Key Features

### Automatic Configuration Updates
- The script automatically updates terraform.tfvars with your inputs
- Creates backups of existing configurations
- Validates email and domain formats
- Enforces secure password requirements

### Cloud-Specific Setup
- **Azure**: Generates SSH key pairs or uses existing ones
- **AWS**: Lists existing EC2 key pairs or creates new ones
- Automatically configures cloud CLI authentication

### Smart Validation
- Checks for required CLI tools (Azure CLI, AWS CLI)
- Validates authentication status
- Provides helpful error messages and setup instructions

### Flexible VM Configuration
- Base configuration is handled interactively
- Advanced VM/instance settings can be modified in terraform.tfvars
- Clear instructions on what can be customized

## Customizing VM/Instance Configuration

After running the interactive setup, you can modify advanced settings by editing the terraform.tfvars file:

### Azure VM Customization
```hcl
# VM Configuration
vm_size = "Standard_B4ms"  # Change VM size
location = "West Europe"   # Change region
os_disk_size = 50         # Increase disk size
os_disk_type = "Premium_LRS"  # Use premium storage

# Network Configuration
allowed_ips = ["203.0.113.0/24"]  # Restrict access to specific IPs
```

### AWS EC2 Customization
```hcl
# Instance Configuration
instance_type = "t3.medium"  # Change instance type
region = "eu-west-1"        # Change region
root_volume_size = 40       # Increase volume size
enable_monitoring = true    # Enable detailed monitoring

# Network Configuration
vpc_cidr = "10.1.0.0/16"   # Change VPC CIDR
subnet_cidr = "10.1.1.0/24"  # Change subnet CIDR
allowed_ips = ["203.0.113.0/24"]  # Restrict access
```

## Post-Deployment Steps

1. **Update DNS**: Point your domain to the public IP address shown in the output
2. **Wait for SSL**: Let's Encrypt certificate generation may take a few minutes
3. **Access n8n**: Visit your configured URL (e.g., https://automation.mydomain.com)
4. **Monitor**: Use the provided SSH commands to check logs and system status

## Troubleshooting

### Common Issues

1. **SSH Key Issues (Azure)**:
   ```bash
   # Generate new key pair
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_n8n_key
   # Update terraform.tfvars with the public key content
   ```

2. **AWS Key Pair Issues**:
   ```bash
   # List existing key pairs
   aws ec2 describe-key-pairs
   # Create new key pair
   aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > ~/.ssh/my-key.pem
   chmod 400 ~/.ssh/my-key.pem
   ```

3. **Authentication Issues**:
   ```bash
   # Azure
   az login
   az account show
   
   # AWS
   aws configure
   aws sts get-caller-identity
   ```

### Getting Help

Run the script with the help flag to see all available options:

```bash
./deploy.sh --help
```

## Best Practices

1. **Start with Development**: Always test in dev environment first
2. **Use Secure Passwords**: Ensure database passwords are strong and unique
3. **Restrict Access**: Update allowed_ips with your specific IP ranges
4. **Monitor Resources**: Check AWS/Azure costs and resource usage
5. **Backup Data**: Regular backups of n8n workflows and database
6. **Keep Updated**: Regularly update Terraform modules and n8n Docker images