# bot-management

Manages `cloudflare_bot_management`, the per zone bot detection configuration.

```hcl
module "bots" {
  source  = "terraform-cf-modules/security/cloudflare//modules/bot-management"
  version = "~> 0.1"

  zone_id = var.zone_id

  enable_js         = true
  auto_update_model = true

  sbfm_definitely_automated       = "block"
  sbfm_likely_automated           = "managed_challenge"
  sbfm_verified_bots              = "allow"
  sbfm_static_resource_protection = false

  ai_bots_protection = "block"
  crawler_protection = "disabled"
}
```

## It is a zone setting, not a resource

The Cloudflare API has no create or delete for this object; it patches settings on a zone that already exists.
Two consequences:

- `terraform destroy` stops Terraform managing the settings. It does not turn bot management off. Whatever
  values were last applied stay in place.
- Every input defaults to `null`, which the provider sends as "leave alone". Setting `enabled = false` on the
  module removes the resource from state without touching the zone.

## Which fields your plan accepts

The available fields depend on the zone plan, and Cloudflare rejects fields the plan does not include.

- `fight_mode` is the Free plan Bot Fight Mode. It is mutually exclusive with the `sbfm_*` fields.
- The `sbfm_*` fields are Super Bot Fight Mode, on Pro and Business.
- `enable_js`, `auto_update_model`, `suppress_session_score`, `ai_bots_protection`, `crawler_protection` and
  `content_bots_protection` belong to the Enterprise Bot Management product.

`stale_zone_configuration` and `using_latest_model` are read only in the provider schema. `using_latest_model`
is exposed as an output; it tells you whether the zone drifted off the current detection model.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_bot_management.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/bot_management) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID whose bot management settings are managed. | `string` | n/a | yes |
| <a name="input_ai_bots_protection"></a> [ai\_bots\_protection](#input\_ai\_bots\_protection) | Rule to block AI scrapers and crawlers. One of block, disabled, only\_on\_ad\_pages. | `string` | `null` | no |
| <a name="input_auto_update_model"></a> [auto\_update\_model](#input\_auto\_update\_model) | Whether to move automatically to each new Cloudflare bot detection model as it is released. | `bool` | `null` | no |
| <a name="input_bm_cookie_enabled"></a> [bm\_cookie\_enabled](#input\_bm\_cookie\_enabled) | Whether the bot management cookie may be placed on end user devices. Cloudflare defaults this to true. | `bool` | `null` | no |
| <a name="input_cf_robots_variant"></a> [cf\_robots\_variant](#input\_cf\_robots\_variant) | Robots Access Control License variant to publish. One of off, policy\_only. | `string` | `null` | no |
| <a name="input_content_bots_protection"></a> [content\_bots\_protection](#input\_content\_bots\_protection) | Rule to block content bots, meaning automated traffic with low bot scores outside the safe verified categories. One of block, disabled. | `string` | `null` | no |
| <a name="input_crawler_protection"></a> [crawler\_protection](#input\_crawler\_protection) | Rule that sends AI scrapers and crawlers into a link maze. One of enabled, disabled. | `string` | `null` | no |
| <a name="input_enable_js"></a> [enable\_js](#input\_enable\_js) | Whether to use lightweight invisible JavaScript detections to improve bot scoring. | `bool` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to manage bot management for the zone. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_fight_mode"></a> [fight\_mode](#input\_fight\_mode) | Whether to enable Bot Fight Mode. Free plan feature, mutually exclusive with Super Bot Fight Mode and with the Bot Management plan settings. | `bool` | `null` | no |
| <a name="input_is_robots_txt_managed"></a> [is\_robots\_txt\_managed](#input\_is\_robots\_txt\_managed) | Whether Cloudflare manages robots.txt for the zone, prepending its own directives to any existing file. | `bool` | `null` | no |
| <a name="input_optimize_wordpress"></a> [optimize\_wordpress](#input\_optimize\_wordpress) | Whether to optimise Super Bot Fight Mode protections for WordPress. | `bool` | `null` | no |
| <a name="input_sbfm_definitely_automated"></a> [sbfm\_definitely\_automated](#input\_sbfm\_definitely\_automated) | Super Bot Fight Mode action for definitely automated requests. One of allow, block, managed\_challenge. | `string` | `null` | no |
| <a name="input_sbfm_likely_automated"></a> [sbfm\_likely\_automated](#input\_sbfm\_likely\_automated) | Super Bot Fight Mode action for likely automated requests. One of allow, block, managed\_challenge. | `string` | `null` | no |
| <a name="input_sbfm_static_resource_protection"></a> [sbfm\_static\_resource\_protection](#input\_sbfm\_static\_resource\_protection) | Whether Super Bot Fight Mode also protects static resources. | `bool` | `null` | no |
| <a name="input_sbfm_verified_bots"></a> [sbfm\_verified\_bots](#input\_sbfm\_verified\_bots) | Super Bot Fight Mode action for verified bot requests. One of allow, block. | `string` | `null` | no |
| <a name="input_suppress_session_score"></a> [suppress\_session\_score](#input\_suppress\_session\_score) | Whether to stop tracking the highest bot score for a session in the bot management cookie. | `bool` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bot_management"></a> [bot\_management](#output\_bot\_management) | The full cloudflare\_bot\_management object, or null when the module is disabled. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module managed the zone setting. |
| <a name="output_id"></a> [id](#output\_id) | Identifier of the bot management configuration, or null when the module is disabled. |
| <a name="output_using_latest_model"></a> [using\_latest\_model](#output\_using\_latest\_model) | Whether the zone is running the latest Cloudflare machine learning model. |
<!-- END_TF_DOCS -->
