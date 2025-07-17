# Outputs for Azure development environment
output "n8n_url" {
  description = "URL to access n8n"
  value       = module.n8n_common.n8n_url
}

output "vm_public_ip" {
  description = "Public IP of the VM"
  value       = module.azure_vm.public_ip_address
}

output "vm_private_ip" {
  description = "Private IP of the VM"
  value       = module.azure_vm.private_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = module.azure_vm.ssh_connection_command
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.azure_vm.resource_group_name
}

output "vm_name" {
  description = "Name of the VM"
  value       = module.azure_vm.vm_name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.azure_vm.storage_account_name
}