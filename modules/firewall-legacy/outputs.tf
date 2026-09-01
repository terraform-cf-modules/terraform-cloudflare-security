output "filter_ids" {
  description = "Map of filter key to the unique identifier of the filter."
  value       = { for k, v in cloudflare_filter.this : k => v.id }
}

output "filters" {
  description = "Map of filter key to the full cloudflare_filter object."
  value       = cloudflare_filter.this
}

output "firewall_rule_ids" {
  description = "Map of firewall rule key to the unique identifier of the rule."
  value       = { for k, v in cloudflare_firewall_rule.this : k => v.id }
}

output "firewall_rules" {
  description = "Map of firewall rule key to the full cloudflare_firewall_rule object."
  value       = cloudflare_firewall_rule.this
}

output "access_rule_ids" {
  description = "Map of access rule key to the unique identifier of the rule."
  value       = { for k, v in cloudflare_access_rule.this : k => v.id }
}

output "access_rules" {
  description = "Map of access rule key to the full cloudflare_access_rule object."
  value       = cloudflare_access_rule.this
}

output "user_agent_blocking_rule_ids" {
  description = "Map of user agent blocking rule key to the unique identifier of the rule."
  value       = { for k, v in cloudflare_user_agent_blocking_rule.this : k => v.id }
}

output "user_agent_blocking_rules" {
  description = "Map of user agent blocking rule key to the full cloudflare_user_agent_blocking_rule object."
  value       = cloudflare_user_agent_blocking_rule.this
}

output "zone_lockdown_ids" {
  description = "Map of zone lockdown key to the unique identifier of the rule."
  value       = { for k, v in cloudflare_zone_lockdown.this : k => v.id }
}

output "zone_lockdowns" {
  description = "Map of zone lockdown key to the full cloudflare_zone_lockdown object."
  value       = cloudflare_zone_lockdown.this
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
