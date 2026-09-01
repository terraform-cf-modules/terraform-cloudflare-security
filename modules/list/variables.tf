variable "enabled" {
  description = "Whether to create the lists. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the lists. Lists are always account scoped, even when only one zone uses them."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "lists" {
  description = <<-EOT
    Lists to create, keyed by a stable identifier. The key is only a Terraform address; `name` is what rule
    expressions reference as `$name`.

    Set `items` to manage the whole list contents inline as a single API object, or leave it null and use the
    `items` variable to manage members as individual `cloudflare_list_item` resources. Do not do both for the
    same list: the provider warns that inline items overwrite everything in the list.
  EOT

  type = map(object({
    name        = string
    kind        = string
    description = optional(string)

    items = optional(set(object({
      ip      = optional(string)
      asn     = optional(number)
      comment = optional(string)
      hostname = optional(object({
        url_hostname           = string
        exclude_exact_hostname = optional(bool)
      }))
      redirect = optional(object({
        source_url            = string
        target_url            = string
        status_code           = optional(number)
        include_subdomains    = optional(bool)
        preserve_path_suffix  = optional(bool)
        preserve_query_string = optional(bool)
        subpath_matching      = optional(bool)
      }))
    })))
  }))
  default = {}

  validation {
    condition     = alltrue([for l in values(var.lists) : contains(["ip", "redirect", "hostname", "asn"], l.kind)])
    error_message = "Each list kind must be one of ip, redirect, hostname, asn."
  }

  validation {
    condition     = alltrue([for l in values(var.lists) : can(regex("^[a-z0-9_]+$", l.name))])
    error_message = "Each list name must contain only lowercase letters, digits and underscores, because rule expressions reference it as $name."
  }

  validation {
    condition = alltrue([
      for l in values(var.lists) : alltrue([
        for i in coalesce(l.items, []) :
        i.redirect == null || i.redirect.status_code == null || contains([301, 302, 307, 308], i.redirect.status_code)
      ])
    ])
    error_message = "Each redirect item status_code must be one of 301, 302, 307, 308."
  }
}

variable "items" {
  description = <<-EOT
    Individual list members managed as separate `cloudflare_list_item` resources, keyed by a stable identifier.

    `list_key` names an entry in `var.lists`. Use this form when the list is large or when membership is
    computed, so that changing one member does not rewrite the whole list.
  EOT

  type = map(object({
    list_key = string
    ip       = optional(string)
    asn      = optional(number)
    comment  = optional(string)
    hostname = optional(object({
      url_hostname           = string
      exclude_exact_hostname = optional(bool)
    }))
    redirect = optional(object({
      source_url            = string
      target_url            = string
      status_code           = optional(number)
      include_subdomains    = optional(bool)
      preserve_path_suffix  = optional(bool)
      preserve_query_string = optional(bool)
      subpath_matching      = optional(bool)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for i in values(var.items) :
      length(compact([
        i.ip,
        i.asn == null ? null : tostring(i.asn),
        i.hostname == null ? null : "hostname",
        i.redirect == null ? null : "redirect",
      ])) == 1
    ])
    error_message = "Each list item must set exactly one of ip, asn, hostname or redirect."
  }

  validation {
    condition = alltrue([
      for i in values(var.items) :
      i.redirect == null || i.redirect.status_code == null || contains([301, 302, 307, 308], i.redirect.status_code)
    ])
    error_message = "Each redirect item status_code must be one of 301, 302, 307, 308."
  }
}
