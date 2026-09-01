locals {
  enabled = var.enabled

  filters                   = local.enabled ? var.filters : {}
  firewall_rules            = local.enabled ? var.firewall_rules : {}
  access_rules              = local.enabled ? var.access_rules : {}
  user_agent_blocking_rules = local.enabled ? var.user_agent_blocking_rules : {}
  zone_lockdowns            = local.enabled ? var.zone_lockdowns : {}
}
