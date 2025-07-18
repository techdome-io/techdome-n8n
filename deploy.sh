#!/bin/bash

# n8n Terraform Deployment Script
# This script helps deploy n8n on Azure or AWS using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_question() {
    echo -e "${CYAN}[QUESTION]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message"
    echo "  --non-interactive      Run in non-interactive mode (requires all parameters)"
    echo "  -c, --cloud CLOUD      Cloud provider (azure|aws) - for non-interactive mode"
    echo "  -e, --env ENVIRONMENT  Environment (dev|prod) - for non-interactive mode"
    echo "  -a, --action ACTION    Action to perform (plan|apply|destroy) - for non-interactive mode"
    echo ""
    echo "Interactive Examples:"
    echo "  $0                     # Interactive mode (recommended)"
    echo ""
    echo "Non-Interactive Examples:"
    echo "  $0 --non-interactive -c azure -e dev -a plan"
    echo "  $0 --non-interactive -c aws -e prod -a apply"
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate domain format
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get user input for n8n configuration
get_n8n_config() {
    print_header "==============================================="
    print_header "          n8n Configuration Setup"
    print_header "==============================================="
    echo ""
    
    # Domain configuration
    while true; do
        print_question "Enter your domain name (e.g., example.com):"
        read -r DOMAIN_NAME
        if [[ -n "$DOMAIN_NAME" ]]; then
            if validate_domain "$DOMAIN_NAME"; then
                break
            else
                print_error "Invalid domain format. Please enter a valid domain name."
            fi
        else
            print_error "Domain name cannot be empty!"
        fi
    done
    
    # Subdomain configuration
    while true; do
        print_question "Enter subdomain for n8n (default: n8n):"
        read -r SUBDOMAIN
        SUBDOMAIN=${SUBDOMAIN:-"n8n"}
        if [[ $SUBDOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
            break
        else
            print_error "Invalid subdomain format. Please use only letters, numbers, and hyphens."
        fi
    done
    
    # Email configuration
    while true; do
        print_question "Enter your email for SSL certificate (e.g., admin@example.com):"
        read -r SSL_EMAIL
        if [[ -n "$SSL_EMAIL" ]]; then
            if validate_email "$SSL_EMAIL"; then
                break
            else
                print_error "Invalid email format. Please enter a valid email address."
            fi
        else
            print_error "Email cannot be empty!"
        fi
    done
    
    # Timezone configuration
    print_question "Enter timezone (default: Asia/Kolkata):"
    read -r TIMEZONE
    TIMEZONE=${TIMEZONE:-"Asia/Kolkata"}
    
    # Database password - use default
    DB_PASSWORD="n8npassn8npass"
    print_info "Using default database password: n8npassn8npass"
    
    # Show configuration summary
    echo ""
    print_header "Configuration Summary:"
    print_info "Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    print_info "Email: ${SSL_EMAIL}"
    print_info "Timezone: ${TIMEZONE}"
    print_info "n8n URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo ""
}

# Function to get Azure-specific configuration
get_azure_config() {
    print_header "==============================================="
    print_header "          Azure Configuration"
    print_header "==============================================="
    echo ""
    
    # SSH Key configuration
    print_info "For Azure VM access, you need an SSH key pair."
    print_question "Do you have an SSH key pair ready? (y/N):"
    read -r has_ssh_key
    
    if [[ ! $has_ssh_key =~ ^[Yy]$ ]]; then
        print_info "Generating SSH key pair..."
        print_question "Enter a name for your SSH key (default: azure_n8n_key):"
        read -r ssh_key_name
        ssh_key_name=${ssh_key_name:-"azure_n8n_key"}
        
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/$ssh_key_name" -N ""
        print_info "SSH key pair generated: $HOME/.ssh/$ssh_key_name"
        SSH_PUBLIC_KEY=$(cat "$HOME/.ssh/$ssh_key_name.pub")
    else
        while true; do
            print_question "Enter the path to your SSH public key (e.g., ~/.ssh/id_rsa.pub):"
            read -r ssh_key_path
            
            # Expand tilde to home directory
            ssh_key_path="${ssh_key_path/#\~/$HOME}"
            
            if [[ -f "$ssh_key_path" ]]; then
                SSH_PUBLIC_KEY=$(cat "$ssh_key_path")
                break
            else
                print_error "SSH key file not found: $ssh_key_path"
            fi
        done
    fi
    
    print_info "SSH public key configured successfully"
}

# Function to get AWS-specific configuration
get_aws_config() {
    print_header "==============================================="
    print_header "          AWS Configuration"
    print_header "==============================================="
    echo ""
    
    # Key pair configuration
    print_info "For AWS EC2 access, you need an EC2 key pair."
    
    # List existing key pairs
    print_info "Checking for existing key pairs..."
    existing_keys=$(aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --output text 2>/dev/null || echo "")
    
    if [[ -n "$existing_keys" ]]; then
        print_info "Existing key pairs found:"
        echo "$existing_keys" | tr '\t' '\n' | while read -r key; do
            print_info "  - $key"
        done
        echo ""
        
        print_question "Do you want to use an existing key pair? (y/N):"
        read -r use_existing_key
        
        if [[ $use_existing_key =~ ^[Yy]$ ]]; then
            while true; do
                print_question "Enter the name of your existing key pair:"
                read -r KEY_NAME
                
                if echo "$existing_keys" | grep -q "$KEY_NAME"; then
                    print_info "Using existing key pair: $KEY_NAME"
                    break
                else
                    print_error "Key pair '$KEY_NAME' not found. Available keys: $existing_keys"
                fi
            done
        else
            create_new_key_pair
        fi
    else
        print_info "No existing key pairs found. Creating a new one..."
        create_new_key_pair
    fi
}

# Function to create new AWS key pair
create_new_key_pair() {
    print_question "Enter a name for your new key pair (default: n8n-$ENVIRONMENT-key):"
    read -r key_name
    KEY_NAME=${key_name:-"n8n-$ENVIRONMENT-key"}
    
    print_info "Creating key pair: $KEY_NAME"
    
    # Create the key pair and save to file
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$HOME/.ssh/$KEY_NAME.pem"
    chmod 400 "$HOME/.ssh/$KEY_NAME.pem"
    
    print_info "Key pair created and saved to: $HOME/.ssh/$KEY_NAME.pem"
    print_info "Key pair name: $KEY_NAME"
}

# Function to wait for n8n to be ready
wait_for_n8n_ready() {
    local vm_ip="$1"
    local ssh_key="$2"
    local max_attempts=30
    local attempt=1
    
    print_info "Waiting for n8n to be ready..."
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "Attempt $attempt/$max_attempts: Checking n8n status..."
        
        if ssh -i "$ssh_key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$vm_ip" 'sudo docker exec n8n-n8n-1 n8n --version' >/dev/null 2>&1; then
            print_info "✅ n8n is ready!"
            return 0
        else
            print_info "⏳ n8n not ready yet, waiting 30 seconds..."
            sleep 30
            ((attempt++))
        fi
    done
    
    print_error "❌ n8n failed to become ready after $max_attempts attempts"
    return 1
}

# Function to setup and import workflows
setup_workflows() {
    print_header "==============================================="
    print_header "          Automated Workflow Import"
    print_header "==============================================="
    echo ""
    
    # Check if workflows directory exists - always look in project root
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$script_dir"
    
    # If we're in an environment subdirectory, go up to find project root
    if [[ "$script_dir" == */environments/* ]]; then
        project_root="$(cd "$script_dir" && cd ../../.. && pwd)"
    fi
    
    local workflows_dir="$project_root/workflows"
    if [[ ! -d "$workflows_dir" ]]; then
        print_warning "No workflows directory found at: $workflows_dir"
        print_info "Skipping workflow import. To add workflows:"
        print_info "1. Create a 'workflows' directory in the project root folder"
        print_info "2. Add your .json workflow files to the directory"
        print_info "3. Re-run the deployment"
        return 0
    fi
    
    # Check if there are workflow files
    local workflow_files=$(find "$workflows_dir" -name "*.json" -not -name "*.backup" | wc -l)
    if [[ $workflow_files -eq 0 ]]; then
        print_warning "No workflow files found in: $workflows_dir"
        print_info "Skipping workflow import. Add .json workflow files to the workflows directory."
        return 0
    fi
    
    print_info "Found $workflow_files workflow files in: $workflows_dir"
    
    # Get VM connection details
    local vm_ip=$(terraform output -raw vm_public_ip 2>/dev/null || terraform output -raw public_ip 2>/dev/null)
    if [[ -z "$vm_ip" ]]; then
        print_error "Could not get VM public IP from terraform output"
        return 1
    fi
    
    local ssh_connection
    local ssh_key
    
    if [[ "$CLOUD" == "azure" ]]; then
        ssh_connection="azureuser@$vm_ip"
        ssh_key="$HOME/.ssh/azure_n8n_key"
        if [[ ! -f "$ssh_key" ]]; then
            # Try to find SSH key from terraform output or common locations
            ssh_key=$(find "$HOME/.ssh" -name "*azure*" -name "*.pem" -o -name "*azure*" -name "id_rsa" 2>/dev/null | head -1)
            if [[ -z "$ssh_key" ]]; then
                print_error "Could not find SSH key for Azure VM"
                return 1
            fi
        fi
    elif [[ "$CLOUD" == "aws" ]]; then
        ssh_connection="ubuntu@$vm_ip"
        ssh_key="$HOME/.ssh/$KEY_NAME.pem"
        if [[ ! -f "$ssh_key" ]]; then
            # Try to find SSH key
            ssh_key=$(find "$HOME/.ssh" -name "*$KEY_NAME*" -name "*.pem" 2>/dev/null | head -1)
            if [[ -z "$ssh_key" ]]; then
                print_error "Could not find SSH key: $KEY_NAME.pem"
                return 1
            fi
        fi
    fi
    
    print_info "Connecting to: $ssh_connection"
    print_info "Using SSH key: $ssh_key"
    
    # Test SSH connection
    if ! ssh -i "$ssh_key" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ssh_connection" 'echo "SSH connection successful"' >/dev/null 2>&1; then
        print_error "❌ Failed to connect to VM via SSH"
        print_info "Please check:"
        print_info "1. VM is running and accessible"
        print_info "2. SSH key is correct: $ssh_key"
        print_info "3. Security group/NSG allows SSH access"
        return 1
    fi
    
    print_info "✅ SSH connection successful"
    
    # Wait for n8n to be ready
    if ! wait_for_n8n_ready "$ssh_connection" "$ssh_key"; then
        print_error "n8n is not ready. Cannot import workflows."
        return 1
    fi
    
    # Copy workflows directory to VM
    print_info "Copying workflows to VM..."
    if ! scp -i "$ssh_key" -o StrictHostKeyChecking=no -r "$workflows_dir" "$ssh_connection:~/" >/dev/null 2>&1; then
        print_error "❌ Failed to copy workflows directory to VM"
        return 1
    fi
    
    print_info "✅ Workflows copied to VM"
    
    # Copy import script to VM
    local import_script="$project_root/import_workflows.py"
    if [[ ! -f "$import_script" ]]; then
        print_error "❌ Import script not found: $import_script"
        print_info "Please ensure import_workflows.py is in the project root directory"
        return 1
    fi
    
    print_info "Copying import script to VM..."
    if ! scp -i "$ssh_key" -o StrictHostKeyChecking=no "$import_script" "$ssh_connection:~/" >/dev/null 2>&1; then
        print_error "❌ Failed to copy import script to VM"
        return 1
    fi
    
    print_info "✅ Import script copied to VM"
    
    # Run workflow import
    print_info "Starting workflow import..."
    if ssh -i "$ssh_key" -o StrictHostKeyChecking=no "$ssh_connection" 'python3 ~/import_workflows.py' 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ^🔧 ]] || [[ "$line" =~ ^===== ]] || [[ "$line" =~ ^🚀 ]] || [[ "$line" =~ ^----- ]]; then
            print_info "$line"
        elif [[ "$line" =~ ^✅ ]]; then
            print_info "$line"
        elif [[ "$line" =~ ^❌ ]]; then
            print_error "$line"
        elif [[ "$line" =~ ^⚠️ ]]; then
            print_warning "$line"
        elif [[ "$line" =~ ^📊 ]]; then
            print_info "$line"
        elif [[ "$line" =~ ^🎉 ]]; then
            print_info "$line"
        else
            echo "$line"
        fi
    done; then
        print_info "✅ Workflow import completed successfully!"
    else
        print_error "❌ Workflow import failed or completed with errors"
        print_info "You can manually import workflows later by:"
        print_info "1. SSH to the VM: ssh -i $ssh_key $ssh_connection"
        print_info "2. Run: python3 ~/import_workflows.py"
    fi
    
    echo ""
}

# Function to get cloud provider choice
get_cloud_provider() {
    print_header "==============================================="
    print_header "          Cloud Provider Selection"
    print_header "==============================================="
    echo ""
    print_info "Available cloud providers:"
    print_info "1. Azure (Azure Virtual Machines)"
    print_info "2. AWS (Amazon EC2)"
    echo ""
    
    while true; do
        print_question "Select cloud provider (1 for Azure, 2 for AWS):"
        read -r cloud_choice
        case $cloud_choice in
            1)
                CLOUD="azure"
                print_info "Selected: Azure"
                break
                ;;
            2)
                CLOUD="aws"
                print_info "Selected: AWS"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 for Azure or 2 for AWS."
                ;;
        esac
    done
}

# Function to get environment choice
get_environment() {
    print_header "==============================================="
    print_header "          Environment Selection"
    print_header "==============================================="
    echo ""
    print_info "Available environments:"
    print_info "1. Development (dev) - Smaller instances, basic storage"
    print_info "2. Production (prod) - Larger instances, premium storage, restricted access"
    echo ""
    
    while true; do
        print_question "Select environment (1 for dev, 2 for prod):"
        read -r env_choice
        case $env_choice in
            1)
                ENVIRONMENT="dev"
                print_info "Selected: Development"
                break
                ;;
            2)
                ENVIRONMENT="prod"
                print_info "Selected: Production"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 for dev or 2 for prod."
                ;;
        esac
    done
}

# Function to get action choice
get_action() {
    print_header "==============================================="
    print_header "          Action Selection"
    print_header "==============================================="
    echo ""
    print_info "Available actions:"
    print_info "1. Plan - Show what will be created/changed (safe, no changes made)"
    print_info "2. Apply - Create/update the infrastructure"
    print_info "3. Destroy - Remove all created infrastructure"
    echo ""
    
    while true; do
        print_question "Select action (1 for plan, 2 for apply, 3 for destroy):"
        read -r action_choice
        case $action_choice in
            1)
                ACTION="plan"
                print_info "Selected: Plan"
                break
                ;;
            2)
                ACTION="apply"
                print_info "Selected: Apply"
                break
                ;;
            3)
                ACTION="destroy"
                print_info "Selected: Destroy"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 for plan, 2 for apply, or 3 for destroy."
                ;;
        esac
    done
}

# Parse command line arguments
CLOUD=""
ENVIRONMENT=""
ACTION=""
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -c|--cloud)
            CLOUD="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Interactive mode
if [[ "$INTERACTIVE" == true ]]; then
    print_header "==============================================="
    print_header "          n8n Terraform Deployment"
    print_header "==============================================="
    echo ""
    print_info "This script will help you deploy n8n on Azure or AWS using Terraform."
    print_info "You can modify VM/instance configurations by editing the terraform.tfvars file."
    echo ""
    
    # Get user inputs
    get_cloud_provider
    get_environment
    get_n8n_config
    
    # Get cloud-specific configuration
    if [[ "$CLOUD" == "azure" ]]; then
        get_azure_config
    elif [[ "$CLOUD" == "aws" ]]; then
        get_aws_config
    fi
    
    get_action
else
    # Non-interactive mode - validate required parameters
    if [[ -z "$CLOUD" || -z "$ENVIRONMENT" || -z "$ACTION" ]]; then
        print_error "Missing required parameters for non-interactive mode"
        show_usage
        exit 1
    fi
fi

# Validate cloud provider
if [[ "$CLOUD" != "azure" && "$CLOUD" != "aws" ]]; then
    print_error "Invalid cloud provider. Must be 'azure' or 'aws'"
    exit 1
fi

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment. Must be 'dev' or 'prod'"
    exit 1
fi

# Validate action
if [[ "$ACTION" != "plan" && "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    print_error "Invalid action. Must be 'plan', 'apply', or 'destroy'"
    exit 1
fi

# Set working directory
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/environments/$ENVIRONMENT/$CLOUD"

# Check if directory exists
if [[ ! -d "$WORK_DIR" ]]; then
    print_error "Directory not found: $WORK_DIR"
    exit 1
fi

# Function to update terraform.tfvars with user inputs
update_tfvars() {
    local tfvars_file="$WORK_DIR/terraform.tfvars"
    
    print_info "Updating terraform.tfvars with your configuration..."
    
    # Create a backup of existing tfvars
    if [[ -f "$tfvars_file" ]]; then
        cp "$tfvars_file" "$tfvars_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Created backup: $tfvars_file.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Update the terraform.tfvars file using a temporary file approach (safer)
    temp_file=$(mktemp)
    
    while IFS= read -r line; do
        case $line in
            domain_name[[:space:]]*=*)
                echo "domain_name = \"$DOMAIN_NAME\""
                ;;
            subdomain[[:space:]]*=*)
                echo "subdomain   = \"$SUBDOMAIN\""
                ;;
            ssl_email[[:space:]]*=*)
                echo "ssl_email   = \"$SSL_EMAIL\""
                ;;
            timezone[[:space:]]*=*)
                echo "timezone    = \"$TIMEZONE\""
                ;;
            db_password[[:space:]]*=*)
                echo "db_password = \"$DB_PASSWORD\""
                ;;
            *)
                echo "$line"
                ;;
        esac
    done < "$tfvars_file" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$tfvars_file"
    
    # Update cloud-specific variables
    if [[ "$CLOUD" == "azure" && -n "$SSH_PUBLIC_KEY" ]]; then
        # Update SSH key using the same temporary file approach
        temp_file2=$(mktemp)
        while IFS= read -r line; do
            case $line in
                ssh_public_key[[:space:]]*=*)
                    echo "ssh_public_key = \"$SSH_PUBLIC_KEY\""
                    ;;
                *)
                    echo "$line"
                    ;;
            esac
        done < "$tfvars_file" > "$temp_file2"
        mv "$temp_file2" "$tfvars_file"
    elif [[ "$CLOUD" == "aws" && -n "$KEY_NAME" ]]; then
        # Update AWS key name using the same temporary file approach
        temp_file3=$(mktemp)
        while IFS= read -r line; do
            case $line in
                key_name[[:space:]]*=*)
                    echo "key_name = \"$KEY_NAME\""
                    ;;
                *)
                    echo "$line"
                    ;;
            esac
        done < "$tfvars_file" > "$temp_file3"
        mv "$temp_file3" "$tfvars_file"
    fi
    
    print_info "terraform.tfvars updated successfully!"
    
    # Validate the updated file (temporarily disabled)
    # if [[ -f "$(dirname "${BASH_SOURCE[0]}")/validate-tfvars.sh" ]]; then
    #     print_info "Validating terraform.tfvars configuration..."
    #     "$(dirname "${BASH_SOURCE[0]}")/validate-tfvars.sh" "$tfvars_file"
    # fi
}

# Function to show tfvars modification instructions
show_tfvars_info() {
    print_header "==============================================="
    print_header "          VM/Instance Configuration"
    print_header "==============================================="
    echo ""
    print_info "Your terraform.tfvars file is located at: $WORK_DIR/terraform.tfvars"
    echo ""
    print_info "You can modify the following VM/instance configurations:"
    
    if [[ "$CLOUD" == "azure" ]]; then
        print_info "Azure VM Settings:"
        print_info "  - vm_size: VM size (e.g., Standard_B2s, Standard_B4ms)"
        print_info "  - location: Azure region (e.g., East US, West Europe)"
        print_info "  - os_disk_size: OS disk size in GB"
        print_info "  - os_disk_type: Storage type (Standard_LRS, Premium_LRS)"
        print_info "  - ssh_public_key: Your SSH public key"
        print_info "  - allowed_ips: List of IPs allowed to access the VM"
    elif [[ "$CLOUD" == "aws" ]]; then
        print_info "AWS EC2 Settings:"
        print_info "  - instance_type: EC2 instance type (e.g., t3.small, t3.medium)"
        print_info "  - region: AWS region (e.g., us-east-1, eu-west-1)"
        print_info "  - key_name: AWS key pair name"
        print_info "  - root_volume_size: Root volume size in GB"
        print_info "  - vpc_cidr: VPC CIDR block"
        print_info "  - allowed_ips: List of IPs allowed to access the instance"
    fi
    
    echo ""
    print_warning "If you need to modify these settings, please edit the terraform.tfvars file before proceeding."
    echo ""
    
    if [[ "$INTERACTIVE" == true ]]; then
        print_question "Do you want to proceed with the current configuration? (y/N):"
        read -r proceed
        if [[ ! $proceed =~ ^[Yy]$ ]]; then
            print_info "Please modify the terraform.tfvars file and run the script again."
            exit 0
        fi
    fi
}

# Update tfvars if in interactive mode and not destroy action
if [[ "$INTERACTIVE" == true && "$ACTION" != "destroy" ]]; then
    update_tfvars
fi

# Show tfvars information
show_tfvars_info

# Check if terraform.tfvars exists
if [[ ! -f "$WORK_DIR/terraform.tfvars" ]]; then
    print_error "terraform.tfvars not found in $WORK_DIR"
    print_info "Please create terraform.tfvars file with required variables"
    exit 1
fi

print_header "==============================================="
print_header "          Starting Terraform Deployment"
print_header "==============================================="
print_info "Cloud Provider: $CLOUD"
print_info "Environment: $ENVIRONMENT"
print_info "Action: $ACTION"
print_info "Working Directory: $WORK_DIR"
echo ""

# Navigate to working directory
cd "$WORK_DIR"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if [[ "$CLOUD" == "azure" ]]; then
        if ! command -v az &> /dev/null; then
            print_error "Azure CLI is not installed."
            print_info "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
            exit 1
        fi
        
        # Check if logged in to Azure
        if ! az account show &> /dev/null; then
            print_error "Not logged in to Azure. Please run 'az login' first."
            exit 1
        fi
        
        print_info "✓ Azure CLI is configured"
        
        # Check if SSH key is configured in tfvars
        if [[ "$INTERACTIVE" == false ]]; then
            if grep -q "ssh-rsa AAAAB3NzaC1yc2E.*your-public-key-here" "$WORK_DIR/terraform.tfvars"; then
                print_warning "Please update your SSH public key in terraform.tfvars"
                print_info "Generate key with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_n8n_key"
            fi
        fi
        
    elif [[ "$CLOUD" == "aws" ]]; then
        if ! command -v aws &> /dev/null; then
            print_error "AWS CLI is not installed."
            print_info "Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
            exit 1
        fi
        
        # Check if AWS credentials are configured
        if ! aws sts get-caller-identity &> /dev/null; then
            print_error "AWS credentials not configured. Please run 'aws configure' first."
            exit 1
        fi
        
        print_info "✓ AWS CLI is configured"
        
        # Check if key pair is configured in tfvars
        if [[ "$INTERACTIVE" == false ]]; then
            if grep -q "your-key-pair-name" "$WORK_DIR/terraform.tfvars"; then
                print_warning "Please update your AWS key pair name in terraform.tfvars"
                print_info "Create key pair with: aws ec2 create-key-pair --key-name n8n-$ENVIRONMENT-key --query 'KeyMaterial' --output text > ~/.ssh/n8n-$ENVIRONMENT-key.pem"
                print_info "Then update key_name in terraform.tfvars"
            fi
        fi
    fi
}

# Check prerequisites
check_prerequisites

# Initialize Terraform if .terraform directory doesn't exist
if [[ ! -d ".terraform" ]]; then
    print_info "Initializing Terraform..."
    terraform init
fi

# Validate Terraform configuration
print_info "Validating Terraform configuration..."
terraform validate

# Perform the requested action
case $ACTION in
    "plan")
        print_info "Running Terraform plan..."
        terraform plan -var-file="terraform.tfvars"
        ;;
    "apply")
        print_info "Running Terraform apply..."
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            print_warning "You are about to deploy to PRODUCTION environment!"
            read -p "Are you sure you want to continue? (yes/NO): " confirm
            if [[ "$confirm" != "yes" ]]; then
                print_info "Deployment cancelled."
                exit 0
            fi
        fi
        terraform apply -var-file="terraform.tfvars" --auto-approve
        
        # Show outputs if apply was successful
        if [[ $? -eq 0 ]]; then
            print_info "Deployment completed successfully!"
            echo ""
            print_info "Outputs:"
            terraform output
            echo ""
            
            # Automated workflow import
            setup_workflows
            
            print_info "Next steps:"
            print_info "1. Point your domain DNS to the public IP address shown above"
            print_info "2. Wait for SSL certificate generation (may take a few minutes)"
            if [[ "$INTERACTIVE" == true ]]; then
                print_info "3. Access n8n at: https://${SUBDOMAIN}.${DOMAIN_NAME}"
            else
                print_info "3. Access n8n at the provided URL"
            fi
            echo ""
            print_info "SSH access:"
            if [[ "$CLOUD" == "azure" ]]; then
                print_info "  ssh azureuser@<public-ip>"
            elif [[ "$CLOUD" == "aws" ]]; then
                print_info "  ssh -i ~/.ssh/<your-key>.pem ubuntu@<public-ip>"
            fi
            echo ""
            print_info "To check n8n logs:"
            print_info "  cd /opt/n8n && sudo docker compose logs -f"
        fi
        ;;
    "destroy")
        print_warning "You are about to DESTROY the $ENVIRONMENT environment on $CLOUD!"
        read -p "Are you sure you want to continue? (yes/NO): " confirm
        if [[ "$confirm" != "yes" ]]; then
            print_info "Destroy cancelled."
            exit 0
        fi
        print_info "Running Terraform destroy..."
        terraform destroy -var-file="terraform.tfvars"
        ;;
esac

print_info "Operation completed!"