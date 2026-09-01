# Wrapper

Applies the root module's WAF baseline to many zones from a single map, so a fleet of zones does not need a
repeated `module` block each.

```hcl
module "zones" {
  source = "terraform-cf-modules/security/cloudflare//wrappers"

  defaults = {
    name_prefix = "platform"

    rate_limit_rules = {
      login = {
        expression          = "(http.request.uri.path eq \"/login\")"
        period              = 60
        requests_per_period = 20
      }
    }
  }

  items = {
    example_com = {
      zone_id = var.example_com_zone_id
    }

    example_org = {
      zone_id = var.example_org_zone_id

      # Overrides replace the default wholesale, they do not merge into it.
      rate_limit_rules = {}

      bot_management = {
        fight_mode = true
      }
    }
  }
}
```

Keys in `items` become the state addresses, so keep them stable. Renaming a key destroys and recreates that
zone's rulesets.

An item value replaces the matching default outright. `try()` picks the first of item, default, module default
and does no deep merge, so an item that sets `custom_rules` supplies the whole map for that zone.

Since the root module is zone scoped, every item needs a `zone_id`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_wrapper"></a> [wrapper](#module\_wrapper) | ../ | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Values applied to every item unless the item overrides them. | `any` | `{}` | no |
| <a name="input_items"></a> [items](#input\_items) | Map of module instances to create, keyed by a stable identifier. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_wrapper"></a> [wrapper](#output\_wrapper) | Map of module outputs, keyed by the same keys as var.items. |
<!-- END_TF_DOCS -->
