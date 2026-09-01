output "policy_ids" {
  description = "Map of policy key to the Page Shield policy identifier."
  value       = { for k, v in cloudflare_page_shield_policy.this : k => v.id }
}

output "policies" {
  description = "Map of policy key to the full cloudflare_page_shield_policy object."
  value       = cloudflare_page_shield_policy.this
}

output "content_scanning" {
  description = "The full cloudflare_content_scanning object, or null when the setting is not managed."
  value       = one(cloudflare_content_scanning.this)
}

output "content_scanning_expression_ids" {
  description = "Map of expression key to the custom scan expression identifier."
  value       = { for k, v in cloudflare_content_scanning_expression.this : k => v.id }
}

output "content_scanning_expressions" {
  description = "Map of expression key to the full cloudflare_content_scanning_expression object."
  value       = cloudflare_content_scanning_expression.this
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
