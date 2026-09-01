output "ids" {
  description = "Map of widget key to the widget identifier, which is also the sitekey."
  value       = { for k, v in cloudflare_turnstile_widget.this : k => v.id }
}

output "sitekeys" {
  description = "Map of widget key to the public sitekey embedded in the page."
  value       = { for k, v in cloudflare_turnstile_widget.this : k => v.sitekey }
}

output "secrets" {
  description = "Map of widget key to the secret key used server side by the siteverify call."
  value       = { for k, v in cloudflare_turnstile_widget.this : k => v.secret }
  sensitive   = true
}

output "widgets" {
  description = "Map of widget key to the full cloudflare_turnstile_widget object."
  value       = cloudflare_turnstile_widget.this
  sensitive   = true
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
