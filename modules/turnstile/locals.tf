locals {
  enabled = var.enabled

  widgets = local.enabled ? var.widgets : {}
}
