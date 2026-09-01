# ruleset

Manages one `cloudflare_ruleset`. This is the building block behind almost everything in the modern Cloudflare
security surface: custom WAF rules, managed ruleset deployment, rate limiting, request and response header
transforms, dynamic redirects, config overrides and custom log fields are all rulesets in different phases.

```hcl
module "custom_waf" {
  source  = "terraform-cf-modules/security/cloudflare//modules/ruleset"
  version = "~> 0.1"

  zone_id = var.zone_id
  name    = "Zone custom firewall rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = {
    allow_office = {
      priority   = 10
      expression = "(ip.src in $office_ips)"
      action     = "skip"
      action_parameters = {
        ruleset = "current"
      }
    }

    block_high_risk_countries = {
      priority   = 100
      expression = "(ip.src.country in {\"T1\"})"
      action     = "block"
      action_parameters = {
        response = {
          status_code  = 403
          content_type = "application/json"
          content      = jsonencode({ error = "forbidden" })
        }
      }
      logging = { enabled = true }
    }
  }
}
```

## Rule ordering

Cloudflare evaluates the rules of a ruleset in list order, but `rules` here is a **map** so that adding or
removing a rule does not renumber every rule after it and produce a large diff.

Order is derived from the optional `priority` number on each rule (default `1000`), then from the map key
alphabetically as a tiebreak. Both are deterministic, so the same configuration always produces the same list.
Use round numbers with gaps (10, 20, 30) so a rule can be inserted later without renumbering.

The `rule_order` output shows the resulting order without applying.

## Scope

Set **exactly one** of `account_id` or `zone_id`. Account scoped rulesets need `kind = "root"` for an entry
point, or `kind = "custom"` for a reusable ruleset that another ruleset executes. Zone entry points use
`kind = "zone"`.

The check is a resource precondition rather than a variable validation, so a module with `enabled = false` never
trips it.

## Phases

`phase` accepts every value the provider accepts:

`ddos_l4`, `ddos_l7`, `http_config_settings`, `http_custom_errors`, `http_log_custom_fields`, `http_ratelimit`,
`http_request_cache_settings`, `http_request_dynamic_redirect`, `http_request_firewall_custom`,
`http_request_firewall_managed`, `http_request_late_transform`, `http_request_origin`, `http_request_redirect`,
`http_request_sanitize`, `http_request_sbfm`, `http_request_transform`, `http_response_cache_settings`,
`http_response_compression`, `http_response_firewall_managed`, `http_response_headers_transform`,
`magic_transit`, `magic_transit_ids_managed`, `magic_transit_managed`, `magic_transit_ratelimit`.

A zone may hold only one entry point ruleset per phase. Two module instances pointing at the same zone and
phase will fight over the same object.

## Which `action_parameters` shapes are modelled

`action_parameters` in the provider is a single flat object with roughly ninety optional attributes; which ones
are legal depends entirely on the rule's `action` and the ruleset's `phase`. This module types the subset that
the security, transform, redirect, config and logging phases need. Anything not listed below is **not**
accepted, and the correct home for it is a cache or performance module.

| Action | Attributes accepted |
|--------|---------------------|
| `execute` | `id`, `overrides` (with `action`, `enabled`, `sensitivity_level`, `categories[]`, `rules[]`), `matched_data.public_key` |
| `skip` | `ruleset`, `rulesets`, `phases`, `products`, `rules` |
| `block` | `response` (`content`, `content_type`, `status_code`) |
| `serve_error` | `asset_name`, `content`, `content_type`, `status_code` |
| `redirect` | `from_value` (`target_url.value` or `target_url.expression`, `status_code`, `preserve_query_string`), `from_list` (`name`, `key`) |
| `rewrite` | `uri.path`, `uri.query`, `headers` (map keyed by header name, each `operation` = `add`/`set`/`remove` plus `value` or `expression`) |
| `score` | `increment` |
| `compress_response` | `algorithms` (plain list of strings, expanded to the provider's object shape) |
| `set_config` | `automatic_https_rewrites`, `autominify`, `bic`, `disable_apps`, `disable_rum`, `disable_zaraz`, `email_obfuscation`, `fonts`, `hotlink_protection`, `mirage`, `opportunistic_encryption`, `polish`, `rocket_loader`, `security_level`, `server_side_excludes`, `ssl`, `sxg`, `request_body_buffering`, `response_body_buffering` |
| `log_custom_field` | `cookie_fields`, `request_fields`, `transformed_request_fields` (plain lists of names), `response_fields`, `raw_response_fields` (lists of `{ name, preserve_duplicates }`) |
| `challenge`, `js_challenge`, `managed_challenge`, `log`, `force_connection_close`, `ddos_dynamic` | no parameters |

Deliberately **not** modelled: `browser_ttl`, `edge_ttl`, `cache`, `cache_key`, `cache_reserve`, `serve_stale`,
`additional_cacheable_ports`, `origin_cache_control`, `origin_error_page_passthru`, `respect_strong_etags`,
`read_timeout`, `vary`, `set_cache_tags` values, the HTTP cache-control atoms (`max_age`, `no_cache`,
`no_store`, `private`, `public`, `immutable`, `must_revalidate`, `must_understand`, `no_transform`,
`proxy_revalidate`, `s_maxage`, `stale_if_error`, `stale_while_revalidate`), and the origin routing shapes
(`origin`, `host_header`, `sni`).

Convenience differences from the raw provider schema:

- `algorithms`, `cookie_fields`, `request_fields` and `transformed_request_fields` take plain lists of strings.
  The module wraps each entry in the `{ name = ... }` object the provider wants.
- `headers` is a map keyed by header name rather than the provider's map of objects with the name repeated,
  which is the same thing but reads better in HCL.

## Validation

Enum inputs validated against the provider schema: `kind`, `phase`, every rule `action`, header `operation`,
`security_level`, `ssl`, `skip` `products`, and compression `algorithms`. A rule with `action = "execute"` must
carry an `action_parameters.id`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_ruleset.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Human readable name of the ruleset. | `string` | n/a | yes |
| <a name="input_phase"></a> [phase](#input\_phase) | Phase the ruleset runs in. Security phases are http\_request\_firewall\_custom, http\_request\_firewall\_managed, http\_ratelimit, http\_response\_firewall\_managed and http\_request\_sbfm. | `string` | n/a | yes |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID for an account scoped ruleset. Set exactly one of account\_id or zone\_id. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Informative description of the ruleset. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the ruleset. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_kind"></a> [kind](#input\_kind) | Kind of the ruleset. Entry point rulesets attached to a zone use `zone`, account entry points use `root`, and reusable rulesets use `custom`. | `string` | `"zone"` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Rules in the ruleset, keyed by a stable identifier. Rules are emitted in ascending `priority` order and then<br/>alphabetically by key, so evaluation order stays deterministic when keys are added or removed.<br/><br/>`action_parameters` covers the shapes used by the security, transform, redirect, config and logging phases.<br/>The caching and origin shapes are deliberately not modelled; see the module README. | <pre>map(object({<br/>    expression  = string<br/>    action      = string<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>    ref         = optional(string)<br/>    priority    = optional(number, 1000)<br/><br/>    logging = optional(object({<br/>      enabled = bool<br/>    }))<br/><br/>    exposed_credential_check = optional(object({<br/>      username_expression = string<br/>      password_expression = string<br/>    }))<br/><br/>    ratelimit = optional(object({<br/>      characteristics            = list(string)<br/>      period                     = number<br/>      counting_expression        = optional(string)<br/>      mitigation_timeout         = optional(number)<br/>      requests_per_period        = optional(number)<br/>      requests_to_origin         = optional(bool)<br/>      score_per_period           = optional(number)<br/>      score_response_header_name = optional(string)<br/>    }))<br/><br/>    action_parameters = optional(object({<br/>      # action = "execute" -- run a managed ruleset.<br/>      id = optional(string)<br/>      overrides = optional(object({<br/>        action            = optional(string)<br/>        enabled           = optional(bool)<br/>        sensitivity_level = optional(string)<br/>        categories = optional(list(object({<br/>          category          = string<br/>          action            = optional(string)<br/>          enabled           = optional(bool)<br/>          sensitivity_level = optional(string)<br/>        })))<br/>        rules = optional(list(object({<br/>          id                = string<br/>          action            = optional(string)<br/>          enabled           = optional(bool)<br/>          score_threshold   = optional(number)<br/>          sensitivity_level = optional(string)<br/>        })))<br/>      }))<br/>      matched_data = optional(object({<br/>        public_key = string<br/>      }))<br/><br/>      # action = "skip"<br/>      ruleset  = optional(string)<br/>      rulesets = optional(list(string))<br/>      phases   = optional(list(string))<br/>      products = optional(list(string))<br/>      rules    = optional(map(list(string)))<br/><br/>      # action = "block" with a custom response.<br/>      response = optional(object({<br/>        content      = string<br/>        content_type = string<br/>        status_code  = number<br/>      }))<br/><br/>      # action = "serve_error"<br/>      asset_name   = optional(string)<br/>      content      = optional(string)<br/>      content_type = optional(string)<br/>      status_code  = optional(number)<br/><br/>      # action = "redirect"<br/>      from_value = optional(object({<br/>        preserve_query_string = optional(bool)<br/>        status_code           = optional(number)<br/>        target_url = object({<br/>          value      = optional(string)<br/>          expression = optional(string)<br/>        })<br/>      }))<br/>      from_list = optional(object({<br/>        key  = string<br/>        name = string<br/>      }))<br/><br/>      # action = "rewrite" in the transform phases.<br/>      uri = optional(object({<br/>        path = optional(object({<br/>          value      = optional(string)<br/>          expression = optional(string)<br/>        }))<br/>        query = optional(object({<br/>          value      = optional(string)<br/>          expression = optional(string)<br/>        }))<br/>      }))<br/>      headers = optional(map(object({<br/>        operation  = string<br/>        value      = optional(string)<br/>        expression = optional(string)<br/>      })))<br/><br/>      # action = "score"<br/>      increment = optional(number)<br/><br/>      # action = "compress_response"<br/>      algorithms = optional(list(string))<br/><br/>      # action = "set_config"<br/>      automatic_https_rewrites = optional(bool)<br/>      autominify = optional(object({<br/>        css  = optional(bool)<br/>        html = optional(bool)<br/>        js   = optional(bool)<br/>      }))<br/>      bic                      = optional(bool)<br/>      disable_apps             = optional(bool)<br/>      disable_rum              = optional(bool)<br/>      disable_zaraz            = optional(bool)<br/>      email_obfuscation        = optional(bool)<br/>      fonts                    = optional(bool)<br/>      hotlink_protection       = optional(bool)<br/>      mirage                   = optional(bool)<br/>      opportunistic_encryption = optional(bool)<br/>      polish                   = optional(string)<br/>      rocket_loader            = optional(bool)<br/>      security_level           = optional(string)<br/>      server_side_excludes     = optional(bool)<br/>      ssl                      = optional(string)<br/>      sxg                      = optional(bool)<br/><br/>      # http_request_sanitize / body buffering.<br/>      request_body_buffering  = optional(string)<br/>      response_body_buffering = optional(string)<br/><br/>      # action = "log_custom_field"<br/>      cookie_fields              = optional(list(string))<br/>      request_fields             = optional(list(string))<br/>      transformed_request_fields = optional(list(string))<br/>      response_fields = optional(list(object({<br/>        name                = string<br/>        preserve_duplicates = optional(bool)<br/>      })))<br/>      raw_response_fields = optional(list(object({<br/>        name                = string<br/>        preserve_duplicates = optional(bool)<br/>      })))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID for a zone scoped ruleset. Set exactly one of account\_id or zone\_id. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_id"></a> [id](#output\_id) | The unique ID of the ruleset, or null when the module is disabled. |
| <a name="output_rule_order"></a> [rule\_order](#output\_rule\_order) | Rule keys in the order they were emitted into the ruleset, after sorting by priority then key. |
| <a name="output_ruleset"></a> [ruleset](#output\_ruleset) | The full cloudflare\_ruleset object, or null when the module is disabled. |
| <a name="output_version"></a> [version](#output\_version) | The version of the ruleset as reported by Cloudflare, or null when the module is disabled. |
<!-- END_TF_DOCS -->
