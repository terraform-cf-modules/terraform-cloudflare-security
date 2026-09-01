# -----------------------------------------------------------------------------
# modules/api-shield
#
# API Shield: client identification, tracked operations, uploaded OpenAPI
# schemas, and schema validation settings.
#
# Cloudflare has two generations of schema validation and the provider exposes
# both. cloudflare_api_shield_schema plus
# cloudflare_api_shield_operation_schema_validation_settings is the original
# pair; cloudflare_schema_validation_schemas plus
# cloudflare_schema_validation_settings is Schema Validation 2.0. Pick one.
# -----------------------------------------------------------------------------

resource "cloudflare_api_shield" "this" {
  count = local.create_api_shield ? 1 : 0

  zone_id                 = var.zone_id
  auth_id_characteristics = var.auth_id_characteristics
}

resource "cloudflare_api_shield_operation" "this" {
  for_each = local.operations

  zone_id  = var.zone_id
  host     = each.value.host
  method   = each.value.method
  endpoint = each.value.endpoint
}

resource "cloudflare_schema_validation_operation_settings" "this" {
  for_each = local.operation_validation_settings

  zone_id           = var.zone_id
  operation_id      = cloudflare_api_shield_operation.this[each.key].id
  mitigation_action = each.value
}

# Deprecated by the provider in favour of cloudflare_schema_validation_operation_settings above. Kept behind a
# flag so existing state can be adopted before being moved.
resource "cloudflare_api_shield_operation_schema_validation_settings" "this" {
  for_each = local.legacy_operation_validation_settings

  zone_id           = var.zone_id
  operation_id      = cloudflare_api_shield_operation.this[each.key].id
  mitigation_action = each.value
}

resource "cloudflare_api_shield_schema" "this" {
  for_each = local.schemas

  zone_id            = var.zone_id
  file               = each.value.file
  name               = each.value.name
  kind               = each.value.kind
  validation_enabled = each.value.validation_enabled ? "true" : "false"
}

resource "cloudflare_schema_validation_schemas" "this" {
  for_each = local.validation_schemas

  zone_id            = var.zone_id
  name               = each.value.name
  source             = each.value.source
  kind               = each.value.kind
  validation_enabled = each.value.validation_enabled
}

resource "cloudflare_schema_validation_settings" "this" {
  count = local.create_schema_validation_settings ? 1 : 0

  zone_id                               = var.zone_id
  validation_default_mitigation_action  = var.schema_validation_settings.default_mitigation_action
  validation_override_mitigation_action = var.schema_validation_settings.override_mitigation_action
}
