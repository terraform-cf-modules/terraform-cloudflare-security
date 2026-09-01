output "id" {
  description = "The unique ID of the ruleset, or null when the module is disabled."
  value       = one(cloudflare_ruleset.this[*].id)
}

output "ruleset" {
  description = "The full cloudflare_ruleset object, or null when the module is disabled."
  value       = one(cloudflare_ruleset.this)
}

output "version" {
  description = "The version of the ruleset as reported by Cloudflare, or null when the module is disabled."
  value       = one(cloudflare_ruleset.this[*].version)
}

output "rule_order" {
  description = "Rule keys in the order they were emitted into the ruleset, after sorting by priority then key."
  value       = local.rule_keys
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
