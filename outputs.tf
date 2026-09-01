output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}

output "managed_ruleset_id" {
  description = "ID of the http_request_firewall_managed entry point ruleset, or null when managed rulesets are not deployed."
  value       = module.managed_ruleset.id
}

output "managed_ruleset" {
  description = "The full cloudflare_ruleset object for the managed WAF phase, or null when it was not created."
  value       = module.managed_ruleset.ruleset
}

output "managed_ruleset_rule_order" {
  description = "Managed ruleset keys in the order they were emitted into the ruleset."
  value       = module.managed_ruleset.rule_order
}

output "custom_ruleset_id" {
  description = "ID of the http_request_firewall_custom entry point ruleset, or null when there are no custom rules."
  value       = module.custom_ruleset.id
}

output "custom_ruleset" {
  description = "The full cloudflare_ruleset object for the custom WAF phase, or null when it was not created."
  value       = module.custom_ruleset.ruleset
}

output "custom_rule_order" {
  description = "Custom rule keys in the order they were emitted into the ruleset."
  value       = module.custom_ruleset.rule_order
}

output "rate_limit_ruleset_id" {
  description = "ID of the http_ratelimit entry point ruleset, or null when there are no rate limit rules."
  value       = module.rate_limit_ruleset.id
}

output "rate_limit_ruleset" {
  description = "The full cloudflare_ruleset object for the rate limiting phase, or null when it was not created."
  value       = module.rate_limit_ruleset.ruleset
}

output "rate_limit_rule_order" {
  description = "Rate limit rule keys in the order they were emitted into the ruleset."
  value       = module.rate_limit_ruleset.rule_order
}

output "bot_management_id" {
  description = "Identifier of the bot management configuration, or null when bot management is not managed."
  value       = module.bot_management.id
}

output "bot_management" {
  description = "The full cloudflare_bot_management object, or null when bot management is not managed."
  value       = module.bot_management.bot_management
}
