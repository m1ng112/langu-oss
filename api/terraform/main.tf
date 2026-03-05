terraform {
  required_version = ">= 1.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Uncomment to use remote state
  # backend "s3" {
  #   bucket = "langu-terraform-state"
  #   key    = "langu-api/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Worker Script
resource "cloudflare_worker_script" "langu_api" {
  account_id = var.cloudflare_account_id
  name       = var.worker_name
  content    = file("${path.module}/../dist/index.js")
  module     = true

  # Plain text bindings
  plain_text_binding {
    name = "AZURE_SPEECH_REGION"
    text = var.azure_speech_region
  }

  plain_text_binding {
    name = "RATE_LIMIT_PER_DAY"
    text = tostring(var.rate_limit_per_day)
  }

  # Secret bindings (set via wrangler or Cloudflare dashboard)
  secret_text_binding {
    name = "AZURE_SPEECH_KEY"
    text = var.azure_speech_key
  }
}

# Worker Route (for custom domain)
resource "cloudflare_worker_route" "langu_api_route" {
  count       = var.zone_id != "" ? 1 : 0
  zone_id     = var.zone_id
  pattern     = "${var.api_domain}/*"
  script_name = cloudflare_worker_script.langu_api.name
}

# Rate Limiting Rule (optional)
resource "cloudflare_ruleset" "rate_limit" {
  count       = var.zone_id != "" ? 1 : 0
  zone_id     = var.zone_id
  name        = "langu-api-rate-limit"
  description = "Rate limiting for langu API"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    action = "block"
    ratelimit {
      characteristics     = ["ip.src"]
      period              = 86400  # 1 day
      requests_per_period = var.rate_limit_per_day
      mitigation_timeout  = 3600   # 1 hour block
    }
    expression  = "(http.request.uri.path contains \"/api/v1/assess\")"
    description = "Rate limit assess endpoint"
    enabled     = true
  }
}
