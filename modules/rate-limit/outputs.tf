output "ids" {
  description = "Map of rate limit key to the unique identifier of the rate limit."
  value       = { for k, v in cloudflare_rate_limit.this : k => v.id }
}

output "rate_limits" {
  description = "Map of rate limit key to the full cloudflare_rate_limit object."
  value       = cloudflare_rate_limit.this
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
