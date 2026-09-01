output "module" {
  description = "All outputs of the root module under test."
  value       = module.this
}

output "managed_ruleset_id" {
  description = "ID of the managed WAF entry point ruleset."
  value       = module.this.managed_ruleset_id
}

output "custom_ruleset_id" {
  description = "ID of the custom WAF entry point ruleset."
  value       = module.this.custom_ruleset_id
}

output "custom_rule_order" {
  description = "Custom rule keys in evaluation order."
  value       = module.this.custom_rule_order
}

output "rate_limit_ruleset_id" {
  description = "ID of the rate limiting entry point ruleset."
  value       = module.this.rate_limit_ruleset_id
}

output "list_ids" {
  description = "IDs of the account lists the WAF rules reference."
  value       = module.lists.ids
}

output "security_headers_ruleset_id" {
  description = "ID of the response header transform ruleset."
  value       = module.security_headers.id
}

output "turnstile_sitekeys" {
  description = "Public Turnstile sitekeys, safe to embed in a page."
  value       = module.turnstile.sitekeys
}

output "turnstile_secrets" {
  description = "Turnstile secret keys, for the server side siteverify call."
  value       = module.turnstile.secrets
  sensitive   = true
}

output "api_shield_operation_ids" {
  description = "UUIDs of the tracked API Shield operations."
  value       = module.api_shield.operation_ids
}

output "page_shield_policy_ids" {
  description = "IDs of the Page Shield policies."
  value       = module.page_shield.policy_ids
}

output "legacy_firewall_rule_ids" {
  description = "IDs of the deprecated firewall rules kept for migration."
  value       = module.legacy_firewall.firewall_rule_ids
}

output "legacy_rate_limit_ids" {
  description = "IDs of the deprecated per zone rate limits."
  value       = module.legacy_rate_limit.ids
}
