output "managed_ruleset_id" {
  description = "ID of the http_request_firewall_managed ruleset."
  value       = module.managed.id
}

output "custom_ruleset_id" {
  description = "ID of the http_request_firewall_custom ruleset."
  value       = module.custom.id
}

output "custom_rule_order" {
  description = "Custom rule keys in evaluation order, which is priority order and not map order."
  value       = module.custom.rule_order
}

output "rate_limit_ruleset_id" {
  description = "ID of the http_ratelimit ruleset."
  value       = module.rate_limit.id
}

output "request_transform_ruleset_id" {
  description = "ID of the http_request_transform ruleset."
  value       = module.request_transform.id
}

output "response_headers_ruleset_id" {
  description = "ID of the http_response_headers_transform ruleset."
  value       = module.response_headers.id
}

output "dynamic_redirect_ruleset_id" {
  description = "ID of the http_request_dynamic_redirect ruleset."
  value       = module.dynamic_redirect.id
}

output "config_settings_ruleset_id" {
  description = "ID of the http_config_settings ruleset."
  value       = module.config_settings.id
}

output "log_custom_fields_ruleset_id" {
  description = "ID of the http_log_custom_fields ruleset."
  value       = module.log_custom_fields.id
}
