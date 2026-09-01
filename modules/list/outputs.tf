output "ids" {
  description = "Map of list key to the unique ID of the list."
  value       = { for k, v in cloudflare_list.this : k => v.id }
}

output "names" {
  description = "Map of list key to the list name used in rule expressions as $name."
  value       = { for k, v in cloudflare_list.this : k => v.name }
}

output "lists" {
  description = "Map of list key to the full cloudflare_list object."
  value       = cloudflare_list.this
}

output "items" {
  description = "Map of item key to the full cloudflare_list_item object."
  value       = cloudflare_list_item.this
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
