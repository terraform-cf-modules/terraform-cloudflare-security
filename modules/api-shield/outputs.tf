output "api_shield_id" {
  description = "Identifier of the API Shield configuration, or null when no auth ID characteristics were given."
  value       = one(cloudflare_api_shield.this[*].id)
}

output "api_shield" {
  description = "The full cloudflare_api_shield object, or null when it was not created."
  value       = one(cloudflare_api_shield.this)
}

output "operation_ids" {
  description = "Map of operation key to the operation UUID, which is what rate limiting and schema settings reference."
  value       = { for k, v in cloudflare_api_shield_operation.this : k => v.id }
}

output "operations" {
  description = "Map of operation key to the full cloudflare_api_shield_operation object."
  value       = cloudflare_api_shield_operation.this
}

output "operation_validation_settings" {
  description = "Map of operation key to the full per operation schema validation settings object, from whichever of the two resources is in use."
  value = merge(
    cloudflare_schema_validation_operation_settings.this,
    cloudflare_api_shield_operation_schema_validation_settings.this,
  )
}

output "schema_ids" {
  description = "Map of schema key to the uploaded schema UUID."
  value       = { for k, v in cloudflare_api_shield_schema.this : k => v.schema_id }
}

output "schemas" {
  description = "Map of schema key to the full cloudflare_api_shield_schema object."
  value       = cloudflare_api_shield_schema.this
}

output "validation_schema_ids" {
  description = "Map of Schema Validation 2.0 schema key to its UUID."
  value       = { for k, v in cloudflare_schema_validation_schemas.this : k => v.schema_id }
}

output "validation_schemas" {
  description = "Map of Schema Validation 2.0 schema key to the full cloudflare_schema_validation_schemas object."
  value       = cloudflare_schema_validation_schemas.this
}

output "schema_validation_settings" {
  description = "The zone level Schema Validation 2.0 settings object, or null when not managed."
  value       = one(cloudflare_schema_validation_settings.this)
}

output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}
