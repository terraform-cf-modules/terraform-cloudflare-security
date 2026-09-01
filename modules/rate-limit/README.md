# rate-limit

Manages `cloudflare_rate_limit`, the **previous generation** zone rate limiting product.

> Cloudflare has deprecated the rate limiting API in favour of the Ruleset Engine, and the provider emits a
> deprecation warning on every plan. This submodule exists so that an existing configuration can be imported and
> managed while it is migrated. For new work use an `http_ratelimit` ruleset: either `modules/ruleset` with
> `phase = "http_ratelimit"`, or the `rate_limit_rules` input on the root module.

```hcl
module "rate_limit" {
  source  = "terraform-cf-modules/security/cloudflare//modules/rate-limit"
  version = "~> 0.1"

  zone_id = var.zone_id

  rate_limits = {
    login = {
      period    = 60
      threshold = 20

      action = {
        mode    = "ban"
        timeout = 600
        response = {
          content_type = "application/json"
          body         = "{\"error\":\"rate limited\"}"
        }
      }

      match = {
        request = {
          url     = "example.com/login"
          methods = ["POST"]
          schemes = ["HTTPS"]
        }
      }
    }
  }
}
```

## Notes

- `action.mode` is one of `simulate`, `ban`, `challenge`, `js_challenge`, `managed_challenge`. `simulate` is the
  default here so a mistyped match does not start blocking traffic on first apply.
- `action.timeout` must be greater than or equal to `period`, and Cloudflare rejects it entirely when `mode` is
  a challenge variant.
- `match.request.url` is a host plus path pattern such as `example.org/path*`. Query strings are not matched.
- `match.response.origin_traffic` is deprecated by Cloudflare; prefer response header matching.
- `bypass` is computed only in the provider schema, so it cannot be set from Terraform.

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
| [cloudflare_rate_limit.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/rate_limit) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID the rate limits belong to. | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the rate limits. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_rate_limits"></a> [rate\_limits](#input\_rate\_limits) | Legacy zone rate limits to create, keyed by a stable identifier. | <pre>map(object({<br/>    period    = number<br/>    threshold = number<br/><br/>    action = object({<br/>      mode    = optional(string, "simulate")<br/>      timeout = optional(number)<br/>      response = optional(object({<br/>        body         = optional(string)<br/>        content_type = optional(string)<br/>      }))<br/>    })<br/><br/>    match = object({<br/>      request = optional(object({<br/>        url     = optional(string)<br/>        methods = optional(list(string))<br/>        schemes = optional(list(string))<br/>      }))<br/>      response = optional(object({<br/>        origin_traffic = optional(bool)<br/>      }))<br/>      headers = optional(list(object({<br/>        name  = optional(string)<br/>        op    = optional(string)<br/>        value = optional(string)<br/>      })))<br/>    })<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of rate limit key to the unique identifier of the rate limit. |
| <a name="output_rate_limits"></a> [rate\_limits](#output\_rate\_limits) | Map of rate limit key to the full cloudflare\_rate\_limit object. |
<!-- END_TF_DOCS -->
