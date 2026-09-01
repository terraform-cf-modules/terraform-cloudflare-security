# -----------------------------------------------------------------------------
# Module: Cloudflare Security
# WAF rulesets, rate limiting, bot management, Turnstile, API Shield, and Page Shield.
#
# The root module applies a WAF baseline to one zone:
#
#   http_request_firewall_managed  Cloudflare's managed rulesets, deployed and overridable
#   http_request_firewall_custom   zone specific rules, in a deterministic order
#   http_ratelimit                 rate limiting rules
#   bot management                 optional, off unless configured
#
# Everything else in this repository is a building block under modules/ and is
# consumed with the double slash source syntax:
#
#   source = "terraform-cf-modules/security/cloudflare//modules/<name>"
# -----------------------------------------------------------------------------

module "managed_ruleset" {
  source = "./modules/ruleset"

  enabled = local.create_managed
  zone_id = var.zone_id

  name        = "${var.name_prefix} managed WAF"
  description = "Cloudflare managed rulesets deployed by Terraform."
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules = local.managed_rules
}

module "custom_ruleset" {
  source = "./modules/ruleset"

  enabled = local.create_custom
  zone_id = var.zone_id

  name        = "${var.name_prefix} custom WAF"
  description = "Zone specific WAF rules managed by Terraform."
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = var.custom_rules
}

module "rate_limit_ruleset" {
  source = "./modules/ruleset"

  enabled = local.create_ratelimit
  zone_id = var.zone_id

  name        = "${var.name_prefix} rate limiting"
  description = "Rate limiting rules managed by Terraform."
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = local.ratelimit_rules
}

module "bot_management" {
  source = "./modules/bot-management"

  enabled = local.create_bots
  # A disabled bot-management module still needs a syntactically valid zone_id for its variable validation,
  # and never reads it, so a placeholder stands in when the module is off.
  zone_id = local.create_bots ? var.zone_id : "00000000000000000000000000000000"

  fight_mode         = try(var.bot_management.fight_mode, null)
  optimize_wordpress = try(var.bot_management.optimize_wordpress, null)

  sbfm_definitely_automated       = try(var.bot_management.sbfm_definitely_automated, null)
  sbfm_likely_automated           = try(var.bot_management.sbfm_likely_automated, null)
  sbfm_verified_bots              = try(var.bot_management.sbfm_verified_bots, null)
  sbfm_static_resource_protection = try(var.bot_management.sbfm_static_resource_protection, null)

  enable_js              = try(var.bot_management.enable_js, null)
  auto_update_model      = try(var.bot_management.auto_update_model, null)
  suppress_session_score = try(var.bot_management.suppress_session_score, null)
  bm_cookie_enabled      = try(var.bot_management.bm_cookie_enabled, null)

  ai_bots_protection      = try(var.bot_management.ai_bots_protection, null)
  crawler_protection      = try(var.bot_management.crawler_protection, null)
  content_bots_protection = try(var.bot_management.content_bots_protection, null)
  cf_robots_variant       = try(var.bot_management.cf_robots_variant, null)
  is_robots_txt_managed   = try(var.bot_management.is_robots_txt_managed, null)
}
