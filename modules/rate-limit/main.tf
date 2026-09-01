# -----------------------------------------------------------------------------
# modules/rate-limit
#
# cloudflare_rate_limit is the legacy zone rate limiting product. New work
# should use an http_ratelimit ruleset instead; see modules/ruleset and the
# rate_limit_rules input on the root module.
# -----------------------------------------------------------------------------

resource "cloudflare_rate_limit" "this" {
  for_each = local.rate_limits

  zone_id   = var.zone_id
  period    = each.value.period
  threshold = each.value.threshold

  action = {
    mode     = each.value.action.mode
    timeout  = each.value.action.timeout
    response = each.value.action.response
  }

  match = {
    request  = each.value.match.request
    response = each.value.match.response
    headers  = each.value.match.headers
  }
}
