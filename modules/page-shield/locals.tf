locals {
  enabled = var.enabled

  policies = local.enabled ? var.policies : {}

  manage_content_scanning = local.enabled && var.content_scanning != null

  content_scanning_expressions = local.enabled && coalesce(var.content_scanning, false) ? var.content_scanning_expressions : {}
}
