output "module" {
  description = "All outputs of the module under test."
  value       = module.this
}

output "managed_ruleset_id" {
  description = "ID of the managed WAF entry point ruleset."
  value       = module.this.managed_ruleset_id
}
