# -----------------------------------------------------------------------------
# modules/list
#
# Account scoped lists referenced from rule expressions as $name, plus their
# members. A list can hold its items inline or delegate them to individual
# cloudflare_list_item resources, never both.
# -----------------------------------------------------------------------------

resource "cloudflare_list" "this" {
  for_each = local.lists

  account_id  = var.account_id
  name        = each.value.name
  kind        = each.value.kind
  description = each.value.description
  items       = each.value.items
}

resource "cloudflare_list_item" "this" {
  for_each = local.items

  account_id = var.account_id
  list_id    = cloudflare_list.this[each.value.list_key].id

  ip       = each.value.ip
  asn      = each.value.asn
  comment  = each.value.comment
  hostname = each.value.hostname
  redirect = each.value.redirect

  lifecycle {
    precondition {
      condition     = try(var.lists[each.value.list_key].items, null) == null
      error_message = "List \"${each.value.list_key}\" sets inline items, so its members cannot also be managed as cloudflare_list_item resources. Inline items overwrite the whole list."
    }
  }
}
