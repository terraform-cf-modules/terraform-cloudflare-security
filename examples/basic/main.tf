# Minimum viable configuration for the Cloudflare Security module.
#
# With nothing but a zone ID, the module deploys the Cloudflare Managed Ruleset and the OWASP Core Ruleset into
# the zone's http_request_firewall_managed phase. That is the baseline.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled = true
  zone_id = var.zone_id
}
