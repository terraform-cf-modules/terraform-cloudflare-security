# -----------------------------------------------------------------------------
# modules/firewall-legacy
#
# The previous generation zone firewall: filters, firewall rules, IP access
# rules, user agent blocking and zone lockdown. Cloudflare has deprecated
# filters and firewall rules in favour of the Ruleset Engine. Present here so an
# existing estate can be imported and migrated, not as a starting point.
# -----------------------------------------------------------------------------

# The v5 provider models cloudflare_filter on the bulk create endpoint: `body` is the create payload and the
# top level attributes are the update payload. Both are set from the same values so create and update agree.
resource "cloudflare_filter" "this" {
  for_each = local.filters

  zone_id     = var.zone_id
  expression  = each.value.expression
  description = each.value.description
  paused      = each.value.paused
  ref         = each.value.ref

  body = [{
    expression  = each.value.expression
    description = each.value.description
    paused      = each.value.paused
    ref         = each.value.ref
  }]
}

resource "cloudflare_firewall_rule" "this" {
  for_each = local.firewall_rules

  zone_id = var.zone_id

  filter = {
    expression  = each.value.filter.expression
    description = each.value.filter.description
    paused      = each.value.filter.paused
    ref         = each.value.filter.ref
  }

  action = {
    mode     = each.value.action.mode
    timeout  = each.value.action.timeout
    response = each.value.action.response
  }
}

resource "cloudflare_access_rule" "this" {
  for_each = local.access_rules

  # Exactly one scope. Zone wins when both are supplied, because a rule cannot carry both.
  account_id = var.zone_id == null ? var.account_id : null
  zone_id    = var.zone_id

  mode  = each.value.mode
  notes = each.value.notes

  configuration = {
    target = each.value.configuration.target
    value  = each.value.configuration.value
  }

  lifecycle {
    precondition {
      condition     = var.zone_id != null || var.account_id != null
      error_message = "An IP access rule needs either zone_id or account_id."
    }
  }
}

resource "cloudflare_user_agent_blocking_rule" "this" {
  for_each = local.user_agent_blocking_rules

  zone_id     = var.zone_id
  mode        = each.value.mode
  description = each.value.description
  paused      = each.value.paused

  configuration = {
    target = "ua"
    value  = each.value.value
  }
}

resource "cloudflare_zone_lockdown" "this" {
  for_each = local.zone_lockdowns

  zone_id     = var.zone_id
  urls        = each.value.urls
  description = each.value.description
  paused      = each.value.paused
  priority    = each.value.priority

  configurations = each.value.configurations
}
