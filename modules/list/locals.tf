locals {
  enabled = var.enabled

  lists = local.enabled ? var.lists : {}
  items = local.enabled ? var.items : {}
}
