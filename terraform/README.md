# n8n Terraform Deployment

This repository contains Terraform modules for deploying n8n on both Azure Virtual Machines and AWS EC2 instances using a modular approach.

## Architecture

The deployment architecture consists of:

- **Common n8n Module**: Shared configuration and user data script
- **Azure VM Module**: Azure-specific infrastructure provisioning
- **AWS EC2 Module**: AWS-specific infrastructure provisioning
- **Environment-specific configurations**: Development and production settings

## Directory Structure

```
terraform/
├── modules/
│   ├── n8n/                    # Common n8n configuration
│   ├── azure-vm/               # Azure VM infrastructure
│   └── aws-ec2/                # AWS EC2 infrastructure
├── environments/
│   ├── dev/
│   │   ├── azure/              # Azure development environment
│   │   └── aws/                # AWS development environment
│   └── prod/
│       ├── azure/              # Azure production environment
│       └── aws/                # AWS production environment
└── README.md
```

## Prerequisites

### For Azure Deployment

1. **Azure CLI**: Install and configure Azure CLI
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   az login
   ```

2. **Service Principal**: Create a service principal with Contributor role
   ```bash
   az ad sp create-for-rbac --name "terraform-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```

3. **SSH Key Pair**: Generate SSH key pair for VM access
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_n8n_key
   ```

### For AWS Deployment

1. **AWS CLI**: Install and configure AWS CLI
   ```bash
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws configure
   ```

2. **IAM User**: Create IAM user with appropriate permissions
   - EC2 Full Access
   - VPC Full Access
   - CloudWatch Full Access

3. **Key Pair**: Create EC2 key pair
   ```bash
   aws ec2 create-key-pair --key-name n8n-dev-key --query 'KeyMaterial' --output text > ~/.ssh/n8n-dev-key.pem
   chmod 400 ~/.ssh/n8n-dev-key.pem
   ```

## Deployment Instructions

### Azure Deployment

1. **Navigate to Azure environment directory**:
   ```bash
   cd terraform/environments/dev/azure
   ```

2. **Update terraform.tfvars**:
   - Update `ssh_public_key` with your public key
   - Update `domain_name` and `subdomain`
   - Update `ssl_email`
   - Update `db_password` with a secure password
   - Update `allowed_ips` with your IP address

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

### AWS Deployment

1. **Navigate to AWS environment directory**:
   ```bash
   cd terraform/environments/dev/aws
   ```

2. **Update terraform.tfvars**:
   - Update `key_name` with your AWS key pair name
   - Update `domain_name` and `subdomain`
   - Update `ssl_email`
   - Update `db_password` with a secure password
   - Update `allowed_ips` with your IP address

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## Post-Deployment

1. **DNS Configuration**: Point your domain/subdomain to the public IP address of the deployed VM/instance.

2. **SSL Certificate**: The deployment automatically configures Let's Encrypt SSL certificates using Traefik.

3. **Access n8n**: Once DNS propagates, access n8n at `https://your-subdomain.your-domain.com`

4. **Monitor Logs**: SSH into the VM/instance and monitor Docker logs:
   ```bash
   # For Azure
   ssh azureuser@<public-ip>
   cd /opt/n8n
   sudo docker compose logs -f

   # For AWS
   ssh -i ~/.ssh/your-key.pem ubuntu@<public-ip>
   cd /opt/n8n
   sudo docker compose logs -f
   ```

## Customization

### Environment-Specific Changes

- **Development**: Uses smaller instance sizes and less restrictive security settings
- **Production**: Uses larger instances, premium storage (Azure), and restrictive security groups

### Module Customization

- **n8n Module**: Modify `modules/n8n/user-data.sh` to change the deployment script
- **Azure Module**: Modify `modules/azure-vm/main.tf` to change Azure-specific settings
- **AWS Module**: Modify `modules/aws-ec2/main.tf` to change AWS-specific settings

### Adding New Environments

1. Create new environment directory (e.g., `terraform/environments/staging/azure`)
2. Copy and modify configuration files from existing environments
3. Update terraform.tfvars with environment-specific values

## Security Considerations

1. **SSH Access**: Restrict SSH access to specific IP addresses
2. **Database Password**: Use strong, unique passwords for each environment
3. **Network Security**: Configure appropriate security groups/NSGs
4. **SSL/TLS**: Let's Encrypt certificates are automatically configured
5. **Regular Updates**: Keep the n8n Docker image updated

## Troubleshooting

### Common Issues

1. **SSH Connection Issues**: Ensure your public key is correctly configured
2. **Docker Service Issues**: Check VM startup logs and Docker service status
3. **SSL Certificate Issues**: Verify DNS configuration and wait for propagation
4. **n8n Access Issues**: Check security group rules and Traefik configuration

### Debugging Commands

```bash
# Check Docker status
sudo systemctl status docker

# Check n8n containers
sudo docker compose ps

# View container logs
sudo docker compose logs -f n8n

# Check Traefik configuration
sudo docker compose logs -f traefik
```

## Cleanup

To destroy the infrastructure:

```bash
# In the appropriate environment directory
terraform destroy -var-file="terraform.tfvars"
```

## Contributing

1. Follow the existing module structure
2. Update documentation for any changes
3. Test changes in development environment before production
4. Use appropriate variable validation and descriptions

## License

This project is licensed under the MIT License.