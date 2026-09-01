# firewall-legacy

Manages the previous generation zone firewall:

| Resource | What it does |
|----------|--------------|
| `cloudflare_filter` | A standalone match expression, reusable by firewall rules |
| `cloudflare_firewall_rule` | A filter plus an action |
| `cloudflare_access_rule` | IP, IP range, ASN or country access rule (zone or account scoped) |
| `cloudflare_user_agent_blocking_rule` | Exact User-Agent header match |
| `cloudflare_zone_lockdown` | Restrict a set of URLs to a set of IPs |

## Read this before using it

**Cloudflare has deprecated the Filters API and the Firewall Rules API in favour of the Ruleset Engine.** The
provider emits a deprecation warning for `cloudflare_filter` and `cloudflare_firewall_rule` on every plan, and
Cloudflare has been auto-migrating existing firewall rules into `http_request_firewall_custom` rulesets.

This submodule exists so that an estate already built on these resources can be brought under Terraform and
migrated deliberately, rather than being rewritten blind. **Do not start here.** For anything new, use
`modules/ruleset` with `phase = "http_request_firewall_custom"`, or the `custom_rules` input on the root module.

`cloudflare_access_rule`, `cloudflare_user_agent_blocking_rule` and `cloudflare_zone_lockdown` are not
deprecated in the provider, but they are legacy security products: the Ruleset Engine covers all three, and a
`skip` rule with `products = ["uaBlock", "zoneLockdown"]` is what lets a ruleset step around them during a
migration.

## Migration mapping

| Legacy | Ruleset equivalent |
|--------|--------------------|
| `cloudflare_firewall_rule` with `action.mode = "block"` | rule with `action = "block"` in `http_request_firewall_custom` |
| `action.mode = "challenge"` / `"js_challenge"` / `"managed_challenge"` | `action = "challenge"` / `"js_challenge"` / `"managed_challenge"` |
| `action.mode = "simulate"` | `action = "log"` |
| `cloudflare_access_rule` on an IP | a `block` rule matching `ip.src` against a list |
| `cloudflare_user_agent_blocking_rule` | a rule matching `http.user_agent` |
| `cloudflare_zone_lockdown` | a rule matching `http.request.uri.path` and `not ip.src in $allowed` |

Filter expressions carry over unchanged; the Rules language is the same in both products.

## Usage

```hcl
module "legacy" {
  source  = "terraform-cf-modules/security/cloudflare//modules/firewall-legacy"
  version = "~> 0.1"

  zone_id = var.zone_id

  firewall_rules = {
    block_php_probes = {
      filter = {
        expression  = "(http.request.uri.path contains \"/wp-admin\")"
        description = "WordPress probing on a non WordPress site"
      }
      action = { mode = "block" }
    }
  }

  access_rules = {
    block_country = {
      mode          = "block"
      notes         = "Sanctioned jurisdiction"
      configuration = { target = "country", value = "T1" }
    }
  }

  zone_lockdowns = {
    admin = {
      urls           = ["example.com/admin*"]
      configurations = [{ target = "ip_range", value = "203.0.113.0/24" }]
    }
  }
}
```

## Provider quirks

- `cloudflare_firewall_rule.filter` is an **inline nested object**, not a filter ID. The v4 pattern of creating
  a `cloudflare_filter` and referencing `filter_id` no longer exists. The standalone `filters` input is here for
  filters that are genuinely shared or that already exist in state; a rule created through `firewall_rules`
  carries its own filter.
- `cloudflare_filter` is modelled on the bulk create endpoint, so it has both a required `body` list and the
  same fields at the top level. The module sets both from one input.
- `cloudflare_firewall_rule` marks `priority`, `paused`, `ref`, `products` and `description` as computed only,
  so they cannot be set from Terraform.
- The provider's description for `cloudflare_firewall_rule.action.mode` is copied from the rate limiting action
  and lists only `simulate`, `ban`, `challenge`, `js_challenge`, `managed_challenge`. The Firewall Rules API
  also accepts `allow`, `block`, `log` and `bypass`, so the module validates against both sets rather than
  making an existing estate unimportable.
- `cloudflare_access_rule` takes `zone_id` **or** `account_id`, never both. When both are supplied to the
  module, the zone wins.
- `cloudflare_user_agent_blocking_rule.configuration.target` only accepts `ua`, so the module sets it and takes
  just the value.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_rules"></a> [access\_rules](#input\_access\_rules) | IP access rules, keyed by a stable identifier. Scoped to the zone when `zone_id` is set and to the account otherwise. | <pre>map(object({<br/>    mode = string<br/>    configuration = object({<br/>      target = string<br/>      value  = string<br/>    })<br/>    notes = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. Only used for account scoped IP access rules; everything else here is zone scoped. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_filters"></a> [filters](#input\_filters) | Standalone `cloudflare_filter` expressions, keyed by a stable identifier. A filter created here can be reused by more than one firewall rule. | <pre>map(object({<br/>    expression  = string<br/>    description = optional(string)<br/>    paused      = optional(bool)<br/>    ref         = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | Legacy firewall rules, keyed by a stable identifier. Each rule owns its filter inline, which is how the v5<br/>provider models the resource: `cloudflare_firewall_rule.filter` is a nested object, not a filter ID. | <pre>map(object({<br/>    filter = object({<br/>      expression  = string<br/>      description = optional(string)<br/>      paused      = optional(bool)<br/>      ref         = optional(string)<br/>    })<br/>    action = object({<br/>      mode    = optional(string, "block")<br/>      timeout = optional(number)<br/>      response = optional(object({<br/>        body         = optional(string)<br/>        content_type = optional(string)<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_user_agent_blocking_rules"></a> [user\_agent\_blocking\_rules](#input\_user\_agent\_blocking\_rules) | User agent blocking rules, keyed by a stable identifier. Each rule matches one exact User-Agent header value. | <pre>map(object({<br/>    mode        = string<br/>    value       = string<br/>    description = optional(string)<br/>    paused      = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID that owns the filters, firewall rules, user agent blocking rules and zone lockdowns. | `string` | `null` | no |
| <a name="input_zone_lockdowns"></a> [zone\_lockdowns](#input\_zone\_lockdowns) | Zone lockdown rules, keyed by a stable identifier. Each rule restricts a set of URLs to a set of IP addresses or ranges. | <pre>map(object({<br/>    urls = list(string)<br/>    configurations = list(object({<br/>      target = string<br/>      value  = string<br/>    }))<br/>    description = optional(string)<br/>    paused      = optional(bool)<br/>    priority    = optional(number)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_rule_ids"></a> [access\_rule\_ids](#output\_access\_rule\_ids) | Map of access rule key to the unique identifier of the rule. |
| <a name="output_access_rules"></a> [access\_rules](#output\_access\_rules) | Map of access rule key to the full cloudflare\_access\_rule object. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_filter_ids"></a> [filter\_ids](#output\_filter\_ids) | Map of filter key to the unique identifier of the filter. |
| <a name="output_filters"></a> [filters](#output\_filters) | Map of filter key to the full cloudflare\_filter object. |
| <a name="output_firewall_rule_ids"></a> [firewall\_rule\_ids](#output\_firewall\_rule\_ids) | Map of firewall rule key to the unique identifier of the rule. |
| <a name="output_firewall_rules"></a> [firewall\_rules](#output\_firewall\_rules) | Map of firewall rule key to the full cloudflare\_firewall\_rule object. |
| <a name="output_user_agent_blocking_rule_ids"></a> [user\_agent\_blocking\_rule\_ids](#output\_user\_agent\_blocking\_rule\_ids) | Map of user agent blocking rule key to the unique identifier of the rule. |
| <a name="output_user_agent_blocking_rules"></a> [user\_agent\_blocking\_rules](#output\_user\_agent\_blocking\_rules) | Map of user agent blocking rule key to the full cloudflare\_user\_agent\_blocking\_rule object. |
| <a name="output_zone_lockdown_ids"></a> [zone\_lockdown\_ids](#output\_zone\_lockdown\_ids) | Map of zone lockdown key to the unique identifier of the rule. |
| <a name="output_zone_lockdowns"></a> [zone\_lockdowns](#output\_zone\_lockdowns) | Map of zone lockdown key to the full cloudflare\_zone\_lockdown object. |
<!-- END_TF_DOCS -->
