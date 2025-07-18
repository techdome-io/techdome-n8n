# AWS-specific variables for n8n deployment
variable "project_name" {
  type        = string
  description = "Name of the project for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for deployment"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "Type of the EC2 instance"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Name of the AWS key pair for EC2 access"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of IP addresses allowed to access the instance"
  default     = ["0.0.0.0/0"]
}

variable "user_data_script" {
  type        = string
  description = "User data script for instance initialization"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for subnet"
  default     = "10.0.1.0/24"
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root volume in GB"
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "Type of the root volume"
  default     = "gp3"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable detailed monitoring"
  default     = false
}

variable "enable_eip" {
  type        = bool
  description = "Enable Elastic IP"
  default     = true
}