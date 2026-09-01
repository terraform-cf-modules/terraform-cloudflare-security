# -----------------------------------------------------------------------------
# modules/page-shield
#
# Page Shield policies plus content scanning. Both are zone scoped.
#
# cloudflare_content_scanning is a zone setting rather than an object, so
# var.content_scanning defaults to null, meaning "do not manage it".
# -----------------------------------------------------------------------------

resource "cloudflare_page_shield_policy" "this" {
  for_each = local.policies

  zone_id     = var.zone_id
  description = each.value.description
  expression  = each.value.expression
  value       = each.value.value
  action      = each.value.action
  enabled     = each.value.enabled
}

resource "cloudflare_content_scanning" "this" {
  count = local.manage_content_scanning ? 1 : 0

  zone_id = var.zone_id
  value   = var.content_scanning ? "enabled" : "disabled"
}

resource "cloudflare_content_scanning_expression" "this" {
  for_each = local.content_scanning_expressions

  zone_id = var.zone_id

  body = [{
    payload = each.value
  }]

  # Custom scan expressions are rejected while content scanning is off.
  depends_on = [cloudflare_content_scanning.this]
}
