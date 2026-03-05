variable "cloudflare_api_token" {
  description = "Cloudflare API token with Workers edit permission"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "worker_name" {
  description = "Name of the Cloudflare Worker"
  type        = string
  default     = "langu-api"
}

variable "azure_speech_key" {
  description = "Azure Speech API key"
  type        = string
  sensitive   = true
}

variable "azure_speech_region" {
  description = "Azure Speech API region"
  type        = string
  default     = "japaneast"
}

variable "rate_limit_per_day" {
  description = "Maximum requests per IP per day"
  type        = number
  default     = 100
}

# Optional: Custom domain configuration
variable "zone_id" {
  description = "Cloudflare Zone ID for custom domain (optional)"
  type        = string
  default     = ""
}

variable "api_domain" {
  description = "Custom API domain (e.g., api.langu.app)"
  type        = string
  default     = "api.langu.app"
}
