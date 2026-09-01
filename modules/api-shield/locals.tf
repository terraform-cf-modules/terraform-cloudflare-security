locals {
  enabled = var.enabled

  create_api_shield = local.enabled && length(var.auth_id_characteristics) > 0

  operations         = local.enabled ? var.operations : {}
  schemas            = local.enabled ? var.schemas : {}
  validation_schemas = local.enabled ? var.validation_schemas : {}

  # Only the operations that asked for their own mitigation action get a settings resource, and only one of the
  # two generations of that resource is used at a time.
  operation_mitigation_actions = {
    for k, o in local.operations : k => o.mitigation_action
    if o.mitigation_action != null
  }

  operation_validation_settings        = var.use_legacy_operation_schema_validation ? {} : local.operation_mitigation_actions
  legacy_operation_validation_settings = var.use_legacy_operation_schema_validation ? local.operation_mitigation_actions : {}

  create_schema_validation_settings = local.enabled && var.schema_validation_settings != null
}
