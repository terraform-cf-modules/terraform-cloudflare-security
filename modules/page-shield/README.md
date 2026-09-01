# page-shield

Manages client side security on a zone: Page Shield policies, and content scanning for uploads.

| Resource | Purpose |
|----------|---------|
| `cloudflare_page_shield_policy` | Allow, log, or add reporting directives for scripts and connections on a page |
| `cloudflare_content_scanning` | Zone switch for scanning uploaded objects for malware |
| `cloudflare_content_scanning_expression` | Custom expression telling the scanner where uploads live in a request |

```hcl
module "page_shield" {
  source  = "terraform-cf-modules/security/cloudflare//modules/page-shield"
  version = "~> 0.1"

  zone_id = var.zone_id

  policies = {
    checkout_allowlist = {
      description = "Only first party and payment provider scripts on checkout"
      expression  = "http.request.uri.path contains \"/checkout\""
      action      = "allow"
      value       = "script-src 'self' https://js.stripe.com"
      enabled     = true
    }
  }

  content_scanning = true

  content_scanning_expressions = {
    upload_field = "lookup_json_string(http.request.body.raw, \"file\")"
  }
}
```

## Notes

- `action` is one of `allow`, `log`, `add_reporting_directives`. Start with `log`: an `allow` policy that
  misses a legitimate script will break the page. The default here is `log` for that reason.
- `value` carries the policy itself. For `allow` and `add_reporting_directives` it is a Content Security Policy
  directive set; for `log` it is the set of resources to report on.
- `description`, `expression`, `value`, `action` and `enabled` are all required by the provider. The module
  defaults `action` and `enabled` and requires the other three.
- `content_scanning` defaults to `null`, meaning the module leaves the zone setting alone. Set it to `true` or
  `false` to take ownership of it. As with other Cloudflare zone settings, destroying the resource stops
  Terraform managing the switch rather than turning it off.
- Custom scan expressions are only accepted while content scanning is enabled, so
  `content_scanning_expressions` is ignored unless `content_scanning = true`, and the expressions carry an
  explicit `depends_on` for the switch. `cloudflare_content_scanning_expression` is modelled on a bulk endpoint
  with a required `body` list; the module writes one payload per resource so a single expression change does
  not rewrite the rest.
- Page Shield policies need a Business plan or above; content scanning is Enterprise.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID that Page Shield and content scanning are configured on. | `string` | n/a | yes |
| <a name="input_content_scanning"></a> [content\_scanning](#input\_content\_scanning) | Whether to turn on content scanning for uploads on the zone. Leave null to not manage the setting at all. | `bool` | `null` | no |
| <a name="input_content_scanning_expressions"></a> [content\_scanning\_expressions](#input\_content\_scanning\_expressions) | Custom scan expressions telling content scanning where to find uploaded objects in a request, keyed by a<br/>stable identifier. Each payload is a Rules language expression such as<br/>`lookup_json_string(http.request.body.raw, "file")`.<br/><br/>Requires `content_scanning = true`. | `map(string)` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Page Shield policies, keyed by a stable identifier.<br/><br/>`expression` selects the requests the policy applies to, in the Cloudflare Rules language. `value` is the<br/>policy itself: a Content Security Policy directive set for the `allow` and `add_reporting_directives`<br/>actions, and the set of allowed resources for `log`. | <pre>map(object({<br/>    description = string<br/>    expression  = string<br/>    value       = string<br/>    action      = optional(string, "log")<br/>    enabled     = optional(bool, true)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_content_scanning"></a> [content\_scanning](#output\_content\_scanning) | The full cloudflare\_content\_scanning object, or null when the setting is not managed. |
| <a name="output_content_scanning_expression_ids"></a> [content\_scanning\_expression\_ids](#output\_content\_scanning\_expression\_ids) | Map of expression key to the custom scan expression identifier. |
| <a name="output_content_scanning_expressions"></a> [content\_scanning\_expressions](#output\_content\_scanning\_expressions) | Map of expression key to the full cloudflare\_content\_scanning\_expression object. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_policies"></a> [policies](#output\_policies) | Map of policy key to the full cloudflare\_page\_shield\_policy object. |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of policy key to the Page Shield policy identifier. |
<!-- END_TF_DOCS -->
