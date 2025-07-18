# n8n Automated Deployment

This repository contains an automated deployment system for n8n with workflow import capabilities. Deploy n8n on Azure or AWS with a single command, including automatic workflow import!

## 🤔 What is n8n?

**n8n** is a workflow automation platform that helps you connect different apps and services together. Think of it like **Zapier** or **Make.com**, but:
- ✅ **Self-hosted** (you own your data)
- ✅ **Free** (no monthly subscription fees)
- ✅ **More powerful** (custom code, complex logic)
- ✅ **Privacy-focused** (everything runs on your servers)

**Example:** Automatically save Gmail attachments to Google Drive, send Slack notifications when someone fills out a form, or sync data between different databases.

## 🎯 What This Project Does

**This project automatically deploys n8n to the cloud with just one command!**

**Perfect for:**
- 🏢 **Businesses** wanting to automate workflows
- 👨‍💻 **Developers** building automation solutions  
- 🔄 **Teams** migrating from Zapier/Make.com
- 📊 **Anyone** needing workflow automation with custom hosting

## ✨ Features

- **🚀 One-Command Deployment**: Deploy complete n8n infrastructure with a single command
- **🔄 Automatic Workflow Import**: Import all your workflows automatically during deployment
- **☁️ Multi-Cloud Support**: Deploy on Azure Virtual Machines or AWS EC2 instances
- **🔒 SSL Certificates**: Automatic SSL certificate generation with Let's Encrypt
- **📊 Comprehensive Monitoring**: Built-in logging and status monitoring
- **🛡️ Security Best Practices**: Secure configurations and network access controls

## 📁 Project Structure

```
techdome-n8n/
├── deploy.sh                    # 🚀 Main deployment script (all-in-one)
├── import_workflows.py          # 📥 Workflow import script
├── workflows/                   # 📋 Place your workflow files here
│   ├── 0001_Telegram_Schedule_Automation_Scheduled.json
│   ├── 0002_Manual_Totp_Automation_Triggered.json
│   └── ... (your workflow files)
├── environments/                # 🌍 Environment configurations
│   ├── dev/                    # Development environment
│   │   ├── azure/              # Azure development settings
│   │   └── aws/                # AWS development settings
│   └── prod/                   # Production environment
│       ├── azure/              # Azure production settings
│       └── aws/                # AWS production settings
└── modules/                    # 🔧 Reusable Terraform modules
    ├── n8n/                    # Common n8n configuration
    ├── azure-vm/               # Azure VM infrastructure
    └── aws-ec2/                # AWS EC2 infrastructure
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

## 🚀 Quick Start Deployment

### Step 1: Add Your Workflows (Optional)
Place your n8n workflow JSON files in the `workflows/` directory:
```bash
# Copy your workflow files to the workflows directory
cp my-workflow.json workflows/
```

### Step 2: Run the Deployment Script
```bash
# Deploy n8n with automatic workflow import
./deploy.sh
```

That's it! The script will guide you through the deployment process with simple questions.

## 📋 Deployment Questions Guide

When you run `./deploy.sh`, you'll be asked these simple questions:

### 1. **Cloud Provider Selection**
```
Available cloud providers:
1. Azure (Azure Virtual Machines)
2. AWS (Amazon EC2)

Select cloud provider (1 for Azure, 2 for AWS): 1
```
**What to choose:** 
- Choose **1** for Azure if you want to deploy on Microsoft Azure
- Choose **2** for AWS if you want to deploy on Amazon Web Services

### 2. **Environment Selection**
```
Available environments:
1. Development (dev) - Smaller instances, basic storage
2. Production (prod) - Larger instances, premium storage, restricted access

Select environment (1 for dev, 2 for prod): 1
```
**What to choose:**
- Choose **1** for development/testing (cheaper, smaller resources)
- Choose **2** for production use (more powerful, more expensive)

### 3. **Domain Configuration**
```
Enter your domain name (e.g., example.com): yourdomain.com
```
**What to enter:** Your domain name (e.g., `techdome.ai`, `mycompany.com`)

### 4. **Subdomain Configuration**
```
Enter subdomain for n8n (default: n8n): dev-n8n
```
**What to enter:** A subdomain for your n8n instance (e.g., `n8n`, `dev-n8n`, `workflows`)
**Final URL will be:** `https://dev-n8n.yourdomain.com`

### 5. **Email for SSL Certificate**
```
Enter your email for SSL certificate (e.g., admin@example.com): admin@yourdomain.com
```
**What to enter:** Your email address for Let's Encrypt SSL certificate notifications

### 6. **Timezone Configuration**
```
Enter timezone (default: Asia/Kolkata): Asia/Kolkata
```
**What to enter:** Your timezone (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`)

### 7. **SSH Key Configuration** (Azure only)
```
Do you have an SSH key pair ready? (y/N): n
```
**What to choose:**
- Choose **y** if you already have an SSH key pair
- Choose **n** to generate a new SSH key pair automatically

### 8. **Action Selection**
```
Available actions:
1. Plan - Show what will be created/changed (safe, no changes made)
2. Apply - Create/update the infrastructure
3. Destroy - Remove all created infrastructure

Select action (1 for plan, 2 for apply, 3 for destroy): 2
```
**What to choose:**
- Choose **1** to see what will be created (preview only)
- Choose **2** to actually deploy n8n
- Choose **3** to remove/destroy existing deployment

### 9. **Final Confirmation**
```
Do you want to proceed with the current configuration? (y/N): y
```
**What to choose:** Type **y** to start the deployment

## 🎯 What Happens During Deployment

The deployment process automatically:

1. **🏗️ Creates Infrastructure** (~5-8 minutes)
   - Virtual Machine/Instance
   - Network security groups
   - Storage accounts
   - Public IP address

2. **🐳 Installs n8n** (~3-5 minutes)
   - Docker and Docker Compose
   - n8n with PostgreSQL database
   - Traefik reverse proxy
   - SSL certificate setup

3. **📥 Imports Workflows** (~30 seconds)
   - Copies workflow files to the server
   - Imports each workflow into n8n
   - Shows import status for each file

4. **✅ Completes Deployment**
   - Provides access URLs
   - Shows SSH connection details
   - Displays next steps

## 📊 Example Deployment Output

```
🚀 Starting import of 5 workflows...
============================================================

[1/5] Processing: 0001_Telegram_Schedule_Automation_Scheduled.json
✅ Imported: 0001_Telegram_Schedule_Automation_Scheduled.json

[2/5] Processing: 0002_Manual_Totp_Automation_Triggered.json
✅ Imported: 0002_Manual_Totp_Automation_Triggered.json

...

📊 Import Summary:
✅ Successfully imported: 5
❌ Failed imports: 0
📁 Total files processed: 5

🎉 All workflows imported successfully!
```

## ✅ After Deployment

### 1. **Point Your Domain to the Server**
After deployment, you'll see output like:
```
🌐 n8n URL: https://dev-n8n.yourdomain.com
🖥️  VM IP: 172.191.57.45
```

**What to do:**
- Log into your domain registrar (GoDaddy, Cloudflare, etc.)
- Add an A record: `dev-n8n` → `172.191.57.45`
- Wait 5-10 minutes for DNS to propagate

### 2. **Access Your n8n Instance**
- **URL:** `https://dev-n8n.yourdomain.com` (SSL certificate is automatic!)
- **First Time:** You'll be prompted to create an admin account
- **Workflows:** Your imported workflows will be available immediately

### 3. **Verify Everything Works**
- ✅ n8n web interface loads
- ✅ All imported workflows are visible
- ✅ SSL certificate is active (green lock icon)
- ✅ Database is working (create a test workflow)

### 4. **Monitor and Troubleshoot** (if needed)
SSH into your server to check logs:
```bash
# Connect to your server
ssh azureuser@172.191.57.45   # (use your actual IP)

# Check if all services are running
cd /opt/n8n
sudo docker compose ps

# View n8n logs
sudo docker compose logs -f n8n
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

## 🔧 Common Issues & Solutions

### ❌ "Can't access n8n website"

**Problem:** You deployed successfully but can't access `https://dev-n8n.yourdomain.com`

**Solutions:**
1. **Check DNS:** Make sure you added the A record correctly
2. **Wait for DNS:** DNS can take 5-30 minutes to propagate
3. **Check IP:** Verify you're using the correct public IP from deployment output
4. **Try HTTP:** Temporarily try `http://dev-n8n.yourdomain.com` (will redirect to HTTPS)

### ❌ "SSL Certificate Error"

**Problem:** Browser shows "Not Secure" or certificate warnings

**Solutions:**
1. **Wait:** SSL certificates take 2-5 minutes to generate after DNS propagates
2. **Check DNS:** Ensure DNS is pointing to the correct server
3. **Restart Services:** SSH to server and run `sudo docker compose restart traefik`

### ❌ "Deployment Failed"

**Problem:** The deployment script shows errors

**Solutions:**
1. **Check Prerequisites:** Ensure Azure CLI or AWS CLI is installed and configured
2. **Check Permissions:** Verify your account has permission to create resources
3. **Try Again:** Sometimes cloud providers have temporary issues, try running `./deploy.sh` again
4. **Check Logs:** Look at the error messages for specific guidance

### ❌ "SSH Connection Refused"

**Problem:** Can't SSH to the server

**Solutions:**
1. **Wait:** Server might still be starting up (wait 2-3 minutes)
2. **Check IP:** Use the correct public IP from deployment output
3. **Check Key:** Ensure you're using the correct SSH key path
4. **Network:** Check if your IP is allowed in security groups

### ❌ "Workflows Not Imported"

**Problem:** Workflows didn't import during deployment

**Solutions:**
1. **Check Files:** Ensure workflow files are valid JSON in the `workflows/` directory
2. **Manual Import:** SSH to server and run `python3 ~/import_workflows.py`
3. **Check Logs:** Look for import errors in the deployment output
4. **Verify Format:** Ensure workflow files have required fields (name, id, nodes, connections)

### 🆘 Get Help

If you're still having issues:

1. **Check Logs:** SSH to your server and run:
   ```bash
   cd /opt/n8n
   sudo docker compose logs -f
   ```

2. **Check Status:** Verify all services are running:
   ```bash
   sudo docker compose ps
   ```

3. **Restart Services:** Try restarting everything:
   ```bash
   sudo docker compose restart
   ```

## 🧹 Cleanup / Remove Deployment

To remove your n8n deployment and clean up all resources:

```bash
# Run the deployment script and select "destroy"
./deploy.sh
```

When prompted, select:
- Your cloud provider (Azure/AWS)
- Your environment (dev/prod)  
- **Action:** Choose **3** (Destroy)

This will safely remove all created resources including:
- Virtual machines/instances
- Storage accounts
- Network security groups
- Public IP addresses
- All associated resources

**⚠️ Warning:** This will permanently delete your n8n instance and all data. Make sure to export any important workflows first!

## Contributing

1. Follow the existing module structure
2. Update documentation for any changes
3. Test changes in development environment before production
4. Use appropriate variable validation and descriptions

## License

This project is licensed under the MIT License.