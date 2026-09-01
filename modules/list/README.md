# list

Manages `cloudflare_list` and `cloudflare_list_item`. Lists hold IP addresses, ASNs, hostnames or redirects and
are referenced from rule expressions by name, for example `ip.src in $office_ips`.

Lists are **account scoped** even when a single zone uses them, so this submodule takes `account_id` and never
`zone_id`.

```hcl
module "lists" {
  source  = "terraform-cf-modules/security/cloudflare//modules/list"
  version = "~> 0.1"

  account_id = var.account_id

  lists = {
    office_ips = {
      name        = "office_ips"
      kind        = "ip"
      description = "Corporate egress ranges"
      items = [
        { ip = "203.0.113.0/24", comment = "London" },
        { ip = "198.51.100.7", comment = "Bastion" },
      ]
    }

    blocked_asns = {
      name = "blocked_asns"
      kind = "asn"
    }
  }

  # Members of blocked_asns are managed one resource at a time.
  items = {
    as64496 = { list_key = "blocked_asns", asn = 64496, comment = "Known scraper" }
    as64497 = { list_key = "blocked_asns", asn = 64497 }
  }
}
```

## Inline items or item resources, not both

`cloudflare_list.items` sends the entire membership in one API call. It is concise and applies atomically, but
every change rewrites the whole list and a large list makes for a large plan diff.

`cloudflare_list_item` manages members individually. Adding one member touches one resource, which is what you
want for a list that changes often or whose contents are computed.

Setting both for the same list would have the inline write silently clobber the individual items, so the module
refuses it with a resource precondition rather than letting the two fight on every apply.

## Naming

`name` is validated to lowercase letters, digits and underscores. Cloudflare rule expressions reference a list
as `$name`, and anything outside that character set is not addressable there.

The map key is a separate Terraform state address. Renaming a key destroys and recreates the list; renaming
`name` breaks every expression that references it.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the lists. Lists are always account scoped, even when only one zone uses them. | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the lists. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_items"></a> [items](#input\_items) | Individual list members managed as separate `cloudflare_list_item` resources, keyed by a stable identifier.<br/><br/>`list_key` names an entry in `var.lists`. Use this form when the list is large or when membership is<br/>computed, so that changing one member does not rewrite the whole list. | <pre>map(object({<br/>    list_key = string<br/>    ip       = optional(string)<br/>    asn      = optional(number)<br/>    comment  = optional(string)<br/>    hostname = optional(object({<br/>      url_hostname           = string<br/>      exclude_exact_hostname = optional(bool)<br/>    }))<br/>    redirect = optional(object({<br/>      source_url            = string<br/>      target_url            = string<br/>      status_code           = optional(number)<br/>      include_subdomains    = optional(bool)<br/>      preserve_path_suffix  = optional(bool)<br/>      preserve_query_string = optional(bool)<br/>      subpath_matching      = optional(bool)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_lists"></a> [lists](#input\_lists) | Lists to create, keyed by a stable identifier. The key is only a Terraform address; `name` is what rule<br/>expressions reference as `$name`.<br/><br/>Set `items` to manage the whole list contents inline as a single API object, or leave it null and use the<br/>`items` variable to manage members as individual `cloudflare_list_item` resources. Do not do both for the<br/>same list: the provider warns that inline items overwrite everything in the list. | <pre>map(object({<br/>    name        = string<br/>    kind        = string<br/>    description = optional(string)<br/><br/>    items = optional(set(object({<br/>      ip      = optional(string)<br/>      asn     = optional(number)<br/>      comment = optional(string)<br/>      hostname = optional(object({<br/>        url_hostname           = string<br/>        exclude_exact_hostname = optional(bool)<br/>      }))<br/>      redirect = optional(object({<br/>        source_url            = string<br/>        target_url            = string<br/>        status_code           = optional(number)<br/>        include_subdomains    = optional(bool)<br/>        preserve_path_suffix  = optional(bool)<br/>        preserve_query_string = optional(bool)<br/>        subpath_matching      = optional(bool)<br/>      }))<br/>    })))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of list key to the unique ID of the list. |
| <a name="output_items"></a> [items](#output\_items) | Map of item key to the full cloudflare\_list\_item object. |
| <a name="output_lists"></a> [lists](#output\_lists) | Map of list key to the full cloudflare\_list object. |
| <a name="output_names"></a> [names](#output\_names) | Map of list key to the list name used in rule expressions as $name. |
<!-- END_TF_DOCS -->
