# -----------------------------------------------------------------------------
# modules/bot-management
#
# cloudflare_bot_management is a singleton per zone: it configures an existing
# zone setting rather than creating an object. Destroying it does not turn bot
# management off, it only stops Terraform managing the setting.
#
# Every input defaults to null so that an unset value is left exactly as the
# zone already has it instead of being reset to a module opinion.
# -----------------------------------------------------------------------------

resource "cloudflare_bot_management" "this" {
  count = local.enabled ? 1 : 0

  zone_id = var.zone_id

  fight_mode         = var.fight_mode
  optimize_wordpress = var.optimize_wordpress

  sbfm_definitely_automated       = var.sbfm_definitely_automated
  sbfm_likely_automated           = var.sbfm_likely_automated
  sbfm_verified_bots              = var.sbfm_verified_bots
  sbfm_static_resource_protection = var.sbfm_static_resource_protection

  enable_js              = var.enable_js
  auto_update_model      = var.auto_update_model
  suppress_session_score = var.suppress_session_score
  bm_cookie_enabled      = var.bm_cookie_enabled

  ai_bots_protection      = var.ai_bots_protection
  crawler_protection      = var.crawler_protection
  content_bots_protection = var.content_bots_protection
  cf_robots_variant       = var.cf_robots_variant
  is_robots_txt_managed   = var.is_robots_txt_managed
}
