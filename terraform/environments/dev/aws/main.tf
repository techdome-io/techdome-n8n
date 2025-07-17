# AWS development environment main configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Common n8n module
module "n8n_common" {
  source = "../../../modules/n8n"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  subdomain    = var.subdomain
  ssl_email    = var.ssl_email
  timezone     = var.timezone
  vm_size      = var.instance_type
  ssh_public_key = ""  # Not used for AWS
  allowed_ips  = var.allowed_ips
  db_password  = var.db_password
  tags         = var.tags
}

# AWS EC2 module
module "aws_ec2" {
  source = "../../../modules/aws-ec2"

  project_name      = var.project_name
  environment       = var.environment
  region            = var.region
  availability_zone = var.availability_zone
  instance_type     = var.instance_type
  key_name          = var.key_name
  allowed_ips       = var.allowed_ips
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  root_volume_size  = var.root_volume_size
  root_volume_type  = var.root_volume_type
  enable_monitoring = var.enable_monitoring
  enable_eip        = var.enable_eip
  user_data_script  = module.n8n_common.user_data_script
  tags              = module.n8n_common.common_tags
}