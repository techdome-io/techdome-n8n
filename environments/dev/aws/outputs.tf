# Outputs for AWS development environment
output "n8n_url" {
  description = "URL to access n8n"
  value       = module.n8n_common.n8n_url
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.aws_ec2.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.aws_ec2.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.aws_ec2.ssh_connection_command
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.aws_ec2.instance_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.aws_ec2.vpc_id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.aws_ec2.subnet_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.aws_ec2.security_group_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.aws_ec2.cloudwatch_log_group_name
}