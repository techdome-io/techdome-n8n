# Variables for AWS development environment
variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "AWS key pair name"
}

variable "allowed_ips" {
  type        = list(string)
  description = "Allowed IP addresses"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR block"
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
}

variable "root_volume_type" {
  type        = string
  description = "Root volume type"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable detailed monitoring"
}

variable "enable_eip" {
  type        = bool
  description = "Enable Elastic IP"
}

variable "domain_name" {
  type        = string
  description = "Domain name"
}

variable "subdomain" {
  type        = string
  description = "Subdomain"
}

variable "ssl_email" {
  type        = string
  description = "SSL email"
}

variable "timezone" {
  type        = string
  description = "Timezone"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}