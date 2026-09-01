locals {
  enabled = var.enabled

  rate_limits = local.enabled ? var.rate_limits : {}
}
