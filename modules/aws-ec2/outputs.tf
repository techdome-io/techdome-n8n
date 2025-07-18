# AWS EC2 module outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = var.enable_eip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.main.private_dns
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.main.availability_zone
}

output "key_name" {
  description = "Key pair name used for the instance"
  value       = aws_instance.main.key_name
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${var.enable_eip ? aws_eip.main[0].public_ip : aws_instance.main.public_ip}"
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.main.name
}