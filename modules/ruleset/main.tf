# -----------------------------------------------------------------------------
# modules/ruleset
#
# One cloudflare_ruleset. The rules input is a keyed map so that adding or
# removing a rule does not shuffle the remaining ones, and evaluation order is
# taken from an explicit priority rather than from map iteration order.
# -----------------------------------------------------------------------------

resource "cloudflare_ruleset" "this" {
  count = local.enabled ? 1 : 0

  account_id  = var.account_id
  zone_id     = var.zone_id
  name        = var.name
  description = var.description
  kind        = var.kind
  phase       = var.phase

  rules = local.rules

  lifecycle {
    precondition {
      condition     = (var.account_id == null) != (var.zone_id == null)
      error_message = "Set exactly one of account_id or zone_id. A ruleset is either account scoped or zone scoped."
    }
  }
}
