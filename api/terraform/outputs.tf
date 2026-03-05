output "worker_name" {
  description = "Deployed worker name"
  value       = cloudflare_worker_script.langu_api.name
}

output "worker_dev_url" {
  description = "Worker development URL"
  value       = "https://${var.worker_name}.${var.cloudflare_account_id}.workers.dev"
}

output "worker_prod_url" {
  description = "Worker production URL (if custom domain configured)"
  value       = var.zone_id != "" ? "https://${var.api_domain}" : "N/A - No custom domain configured"
}
