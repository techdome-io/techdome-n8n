# Common outputs for n8n module
output "n8n_url" {
  description = "URL to access n8n instance"
  value       = "https://${var.subdomain}.${var.domain_name}"
}