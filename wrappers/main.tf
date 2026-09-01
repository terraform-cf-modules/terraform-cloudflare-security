# -----------------------------------------------------------------------------
# Wrapper: apply the WAF baseline to many zones from a single map.
#
#   module "zones" {
#     source = "terraform-cf-modules/security/cloudflare//wrappers"
#
#     defaults = {
#       name_prefix = "platform"
#       rate_limit_rules = {
#         login = {
#           expression          = "(http.request.uri.path eq \"/login\")"
#           period              = 60
#           requests_per_period = 20
#         }
#       }
#     }
#
#     items = {
#       example_com = { zone_id = var.example_com_zone_id }
#       example_org = { zone_id = var.example_org_zone_id, managed_rulesets_enabled = false }
#     }
#   }
# -----------------------------------------------------------------------------

module "wrapper" {
  source = "../"

  for_each = var.items

  enabled    = try(each.value.enabled, var.defaults.enabled, true)
  account_id = try(each.value.account_id, var.defaults.account_id, null)
  zone_id    = try(each.value.zone_id, var.defaults.zone_id, null)

  name_prefix = try(each.value.name_prefix, var.defaults.name_prefix, "terraform")

  managed_rulesets_enabled = try(each.value.managed_rulesets_enabled, var.defaults.managed_rulesets_enabled, true)
  managed_rulesets = try(each.value.managed_rulesets, var.defaults.managed_rulesets, {
    cloudflare_managed = {
      id          = "efb7b8c949ac4650a09736fc376e9aee"
      description = "Cloudflare Managed Ruleset"
      priority    = 10
    }
    owasp_core = {
      id          = "4814384a9e5d4991b9815dcfc25d2f1f"
      description = "Cloudflare OWASP Core Ruleset"
      priority    = 20
    }
  })

  custom_rules     = try(each.value.custom_rules, var.defaults.custom_rules, {})
  rate_limit_rules = try(each.value.rate_limit_rules, var.defaults.rate_limit_rules, {})
  bot_management   = try(each.value.bot_management, var.defaults.bot_management, null)
}
