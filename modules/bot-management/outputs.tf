output "id" {
  description = "Identifier of the bot management configuration, or null when the module is disabled."
  value       = one(cloudflare_bot_management.this[*].id)
}

output "bot_management" {
  description = "The full cloudflare_bot_management object, or null when the module is disabled."
  value       = one(cloudflare_bot_management.this)
}

output "using_latest_model" {
  description = "Whether the zone is running the latest Cloudflare machine learning model."
  value       = one(cloudflare_bot_management.this[*].using_latest_model)
}

output "enabled" {
  description = "Whether this module managed the zone setting."
  value       = local.enabled
}
