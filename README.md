<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>

<h1 align="center">Terraform Cloudflare Security</h1>
<p align="center"><em>WAF rulesets, rate limiting, bot management, Turnstile, API Shield, and Page Shield.</em></p>

<p align="center">
  <a href="https://www.terraform.io"><img src="https://img.shields.io/badge/terraform-%3E%3D%201.12-844FBA?logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://opentofu.org"><img src="https://img.shields.io/badge/opentofu-%3E%3D%201.12-FFDA18?logo=opentofu&logoColor=black" alt="OpenTofu" /></a>
  <a href="https://registry.terraform.io/providers/cloudflare/cloudflare/latest"><img src="https://img.shields.io/badge/provider-cloudflare%20~%3E%205.24-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Provider" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License" /></a>
</p>

---

## What this is

The Cloudflare security surface, as one Terraform module: WAF rulesets, rate limiting, lists, bot management,
the legacy firewall, Turnstile, API Shield and Page Shield.

The root module applies a **WAF baseline** to a zone. Give it a zone ID and nothing else and it deploys the
Cloudflare Managed Ruleset and the OWASP Core Ruleset into the managed WAF phase. Add rules and it builds a
custom WAF phase and a rate limiting phase alongside, with evaluation order taken from an explicit priority
rather than from map iteration order.

That baseline, and the ordering discipline behind it, is the opinion this module encodes. `cloudflare_ruleset`
is the most complex resource in the provider — one flat `action_parameters` object with roughly ninety optional
attributes whose legality depends on the rule action and the ruleset phase — and generated raw resource blocks
give you none of it.

---

## Usage

### The baseline

```hcl
module "security" {
  source  = "terraform-cf-modules/security/cloudflare"
  version = "~> 0.1"

  zone_id = var.zone_id
}
```

### The baseline plus zone specific rules

```hcl
module "security" {
  source  = "terraform-cf-modules/security/cloudflare"
  version = "~> 0.1"

  zone_id     = var.zone_id
  name_prefix = "platform"

  # Deployed managed rulesets, with category and rule level overrides.
  managed_rulesets = {
    cloudflare_managed = {
      id       = "efb7b8c949ac4650a09736fc376e9aee"
      priority = 10
      overrides = {
        enabled    = true
        categories = [{ category = "wordpress", action = "block" }]
      }
    }
    owasp_core = {
      id       = "4814384a9e5d4991b9815dcfc25d2f1f"
      priority = 20
    }
  }

  # Evaluation order comes from priority, not from where the rule sits in the map.
  custom_rules = {
    allow_office = {
      priority   = 10
      expression = "(ip.src in $office_ips)"
      action     = "skip"
      action_parameters = {
        ruleset = "current"
      }
    }

    block_admin_from_outside = {
      priority   = 100
      expression = "(starts_with(http.request.uri.path, \"/admin\") and not ip.src in $office_ips)"
      action     = "block"
      action_parameters = {
        response = {
          status_code  = 403
          content_type = "application/json"
          content      = jsonencode({ error = "forbidden" })
        }
      }
    }
  }

  rate_limit_rules = {
    login = {
      priority            = 10
      expression          = "(http.request.uri.path eq \"/login\" and http.request.method eq \"POST\")"
      period              = 60
      requests_per_period = 20
      mitigation_timeout  = 600
    }
  }

  bot_management = {
    enable_js          = true
    ai_bots_protection = "block"
  }
}
```

### A single building block

```hcl
module "response_headers" {
  source  = "terraform-cf-modules/security/cloudflare//modules/ruleset"
  version = "~> 0.1"

  zone_id = var.zone_id
  name    = "Security headers"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules = {
    harden = {
      expression = "true"
      action     = "rewrite"
      action_parameters = {
        headers = {
          "Strict-Transport-Security" = { operation = "set", value = "max-age=31536000; includeSubDomains" }
          "X-Content-Type-Options"    = { operation = "set", value = "nosniff" }
          "Server"                    = { operation = "remove" }
        }
      }
    }
  }
}
```

### Many zones at once

```hcl
module "zones" {
  source = "terraform-cf-modules/security/cloudflare//wrappers"

  defaults = {
    name_prefix = "platform"
  }

  items = {
    example_com = { zone_id = var.example_com_zone_id }
    example_org = { zone_id = var.example_org_zone_id, managed_rulesets_enabled = false }
  }
}
```

---

## Submodules

| Module | Resources |
|--------|-----------|
| [`modules/ruleset`](modules/ruleset) | `cloudflare_ruleset` in any phase |
| [`modules/rate-limit`](modules/rate-limit) | `cloudflare_rate_limit` (deprecated by Cloudflare) |
| [`modules/list`](modules/list) | `cloudflare_list`, `cloudflare_list_item` |
| [`modules/bot-management`](modules/bot-management) | `cloudflare_bot_management` |
| [`modules/firewall-legacy`](modules/firewall-legacy) | `cloudflare_filter`, `cloudflare_firewall_rule`, `cloudflare_access_rule`, `cloudflare_user_agent_blocking_rule`, `cloudflare_zone_lockdown` |
| [`modules/turnstile`](modules/turnstile) | `cloudflare_turnstile_widget` |
| [`modules/api-shield`](modules/api-shield) | `cloudflare_api_shield`, `cloudflare_api_shield_operation`, `cloudflare_api_shield_schema`, `cloudflare_api_shield_operation_schema_validation_settings`, `cloudflare_schema_validation_operation_settings`, `cloudflare_schema_validation_schemas`, `cloudflare_schema_validation_settings` |
| [`modules/page-shield`](modules/page-shield) | `cloudflare_page_shield_policy`, `cloudflare_content_scanning`, `cloudflare_content_scanning_expression` |

---

## Examples

| Example | What it shows |
|---------|---------------|
| [`examples/basic`](examples/basic) | The baseline, with nothing but a zone ID |
| [`examples/complete`](examples/complete) | Every optional feature, root module and every submodule |
| [`examples/ruleset-phases`](examples/ruleset-phases) | One ruleset per phase, built directly from `modules/ruleset`, and how rule ordering works |

---

## Things worth knowing before you apply

- **A zone has exactly one entry point ruleset per phase.** Two module instances targeting the same zone and
  phase will fight over the same object. Creating an empty entry point ruleset does not add nothing, it takes
  ownership of the phase and clears whatever was there. The root module therefore creates a phase's ruleset
  only when there is something to put in it.
- **Rule order comes from `priority`, then from the map key.** Not from map order. Use round numbers with gaps.
- **A rule expression referencing a list creates no dependency.** `ip.src in $office_ips` is a string, so
  Terraform cannot see the list behind it. Create lists first, in `modules/list`, which is account scoped.
- **`modules/rate-limit` and `modules/firewall-legacy` are for migration only.** Cloudflare deprecated the rate
  limiting, filters and firewall rules APIs in favour of the Ruleset Engine and the provider warns on every
  plan. New work belongs in a ruleset.
- **Bot management and content scanning are zone settings, not objects.** Destroying them stops Terraform
  managing the setting rather than turning the feature off.
- **Managed ruleset IDs come from Cloudflare, not from the provider schema.** The defaults in
  `var.managed_rulesets` are the published IDs for the Cloudflare Managed Ruleset and the OWASP Core Ruleset.
  Confirm them for your account with `GET /zones/{zone_id}/rulesets`.

[`docs/architecture.md`](docs/architecture.md) has the full resource map, the supported `action_parameters`
shapes, and the provider quirks in detail.

---

## Repository layout

```
terraform.tf          provider and version requirements
main.tf               root module composition
variables.tf          root module inputs
outputs.tf            root module outputs
locals.tf             locals
modules/<name>/       composable building blocks, same file layout
examples/             basic, complete, ruleset-phases
wrappers/             for_each wrapper for many zones
tests/                native terraform test files
docs/                 architecture notes
```

---

## Local development

```bash
pre-commit install

make fmt        # terraform fmt -recursive
make validate   # init and validate every directory
make lint       # tflint
make docs       # regenerate the terraform-docs blocks
make test       # mocked terraform test, no credentials needed
make security   # trivy, checkov, gitleaks
make ci         # all of the above
```

`make test` runs against `mock_provider`, so it needs no Cloudflare credentials. The live tests in
`tests/integration.tftest.hcl` run only on schedule and manual dispatch.

---

## CI

Most workflows call the shared, actively maintained
[clouddrove/github-shared-workflows](https://github.com/clouddrove/github-shared-workflows) at `@v2`, so the
standard changes in one place for every repository.

| Workflow | Source | Purpose |
|----------|--------|---------|
| `tf-checks` | shared | init and validate the examples |
| `tflint` | shared | lint |
| `checkov` | shared | policy scan |
| `gitleaks` | shared | secret scan |
| `pr_checks` | shared | Conventional Commit pull request title |
| `auto_assignee` | shared | reviewer assignment |
| `automerge` | shared | auto merge on green |
| `stale_pr` | shared | stale handling |
| `readme` | shared | rebuild README from README.yaml |
| `tag-release` | shared | tag and changelog on merge |
| `opentofu` | local | OpenTofu compatibility, no shared equivalent yet |
| `test` | local | `terraform test` with mocked provider |
| `integration` | local | live apply against a test account, scheduled only |

### Required organisation secrets

| Secret | Used by |
|--------|---------|
| `GITHUB` | `tflint`, `tag-release`, `auto_assignee`, `automerge`, `readme` |
| `SLACK_WEBHOOK_TERRAFORM` | `readme` |
| `CLOUDFLARE_API_TOKEN` | `integration` |
| `CLOUDFLARE_TEST_ACCOUNT_ID` | `integration` |
| `CLOUDFLARE_TEST_ZONE_ID` | `integration` |

---

## Inputs and outputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bot_management"></a> [bot\_management](#module\_bot\_management) | ./modules/bot-management | n/a |
| <a name="module_custom_ruleset"></a> [custom\_ruleset](#module\_custom\_ruleset) | ./modules/ruleset | n/a |
| <a name="module_managed_ruleset"></a> [managed\_ruleset](#module\_managed\_ruleset) | ./modules/ruleset | n/a |
| <a name="module_rate_limit_ruleset"></a> [rate\_limit\_ruleset](#module\_rate\_limit\_ruleset) | ./modules/ruleset | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. Accepted for interface consistency with the other modules in this organisation and with the account scoped submodules; the root module itself is zone scoped and does not use it. | `string` | `null` | no |
| <a name="input_bot_management"></a> [bot\_management](#input\_bot\_management) | Zone bot management settings. Leave null to not manage them at all.<br/><br/>Which fields the zone accepts depends on its plan: `fight_mode` is Free, the `sbfm_*` fields are Super Bot<br/>Fight Mode on Pro and Business, and the rest belong to Enterprise Bot Management. Any field left null is<br/>left exactly as the zone already has it. | <pre>object({<br/>    fight_mode         = optional(bool)<br/>    optimize_wordpress = optional(bool)<br/><br/>    sbfm_definitely_automated       = optional(string)<br/>    sbfm_likely_automated           = optional(string)<br/>    sbfm_verified_bots              = optional(string)<br/>    sbfm_static_resource_protection = optional(bool)<br/><br/>    enable_js              = optional(bool)<br/>    auto_update_model      = optional(bool)<br/>    suppress_session_score = optional(bool)<br/>    bm_cookie_enabled      = optional(bool)<br/><br/>    ai_bots_protection      = optional(string)<br/>    crawler_protection      = optional(string)<br/>    content_bots_protection = optional(string)<br/>    cf_robots_variant       = optional(string)<br/>    is_robots_txt_managed   = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_custom_rules"></a> [custom\_rules](#input\_custom\_rules) | Zone specific WAF rules, keyed by a stable identifier. Emitted in ascending `priority` order, then by key.<br/><br/>This is the opinionated subset of the ruleset engine that a custom firewall phase actually uses. For<br/>transform, redirect, cache or logging phases, or for an action parameter shape not listed here, call<br/>`modules/ruleset` directly. | <pre>map(object({<br/>    expression  = string<br/>    action      = optional(string, "block")<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>    ref         = optional(string)<br/>    priority    = optional(number, 1000)<br/><br/>    logging = optional(object({<br/>      enabled = bool<br/>    }))<br/><br/>    exposed_credential_check = optional(object({<br/>      username_expression = string<br/>      password_expression = string<br/>    }))<br/><br/>    action_parameters = optional(object({<br/>      # action = "block"<br/>      response = optional(object({<br/>        content      = string<br/>        content_type = string<br/>        status_code  = number<br/>      }))<br/><br/>      # action = "skip"<br/>      ruleset  = optional(string)<br/>      rulesets = optional(list(string))<br/>      phases   = optional(list(string))<br/>      products = optional(list(string))<br/>      rules    = optional(map(list(string)))<br/><br/>      # action = "execute"<br/>      id = optional(string)<br/>      overrides = optional(object({<br/>        action            = optional(string)<br/>        enabled           = optional(bool)<br/>        sensitivity_level = optional(string)<br/>        categories = optional(list(object({<br/>          category          = string<br/>          action            = optional(string)<br/>          enabled           = optional(bool)<br/>          sensitivity_level = optional(string)<br/>        })))<br/>        rules = optional(list(object({<br/>          id                = string<br/>          action            = optional(string)<br/>          enabled           = optional(bool)<br/>          score_threshold   = optional(number)<br/>          sensitivity_level = optional(string)<br/>        })))<br/>      }))<br/>      matched_data = optional(object({<br/>        public_key = string<br/>      }))<br/><br/>      # action = "redirect"<br/>      from_value = optional(object({<br/>        preserve_query_string = optional(bool)<br/>        status_code           = optional(number)<br/>        target_url = object({<br/>          value      = optional(string)<br/>          expression = optional(string)<br/>        })<br/>      }))<br/>      from_list = optional(object({<br/>        key  = string<br/>        name = string<br/>      }))<br/><br/>      # action = "score"<br/>      increment = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this module. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_managed_rulesets"></a> [managed\_rulesets](#input\_managed\_rulesets) | Cloudflare managed rulesets to execute, keyed by a stable identifier.<br/><br/>`id` is the Cloudflare ruleset ID to run. The defaults deploy the Cloudflare Managed Ruleset and the<br/>Cloudflare OWASP Core Ruleset, which is the baseline this module exists to encode. The IDs are Cloudflare's<br/>published managed ruleset IDs, not values from the provider schema; confirm them for your account with<br/>`GET /zones/{zone_id}/rulesets` before relying on them, and override the map to change the set.<br/><br/>Set this to `{}` to deploy no managed rulesets while still managing the phase entry point. | <pre>map(object({<br/>    id          = string<br/>    expression  = optional(string, "true")<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>    priority    = optional(number, 1000)<br/><br/>    overrides = optional(object({<br/>      action            = optional(string)<br/>      enabled           = optional(bool)<br/>      sensitivity_level = optional(string)<br/>      categories = optional(list(object({<br/>        category          = string<br/>        action            = optional(string)<br/>        enabled           = optional(bool)<br/>        sensitivity_level = optional(string)<br/>      })))<br/>      rules = optional(list(object({<br/>        id                = string<br/>        action            = optional(string)<br/>        enabled           = optional(bool)<br/>        score_threshold   = optional(number)<br/>        sensitivity_level = optional(string)<br/>      })))<br/>    }))<br/><br/>    matched_data_public_key = optional(string)<br/>  }))</pre> | <pre>{<br/>  "cloudflare_managed": {<br/>    "description": "Cloudflare Managed Ruleset",<br/>    "id": "efb7b8c949ac4650a09736fc376e9aee",<br/>    "priority": 10<br/>  },<br/>  "owasp_core": {<br/>    "description": "Cloudflare OWASP Core Ruleset",<br/>    "id": "4814384a9e5d4991b9815dcfc25d2f1f",<br/>    "priority": 20<br/>  }<br/>}</pre> | no |
| <a name="input_managed_rulesets_enabled"></a> [managed\_rulesets\_enabled](#input\_managed\_rulesets\_enabled) | Whether to deploy the managed WAF rulesets in var.managed\_rulesets. Set to false to keep the input but stop managing the http\_request\_firewall\_managed entry point. | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix applied to the name of every ruleset this module creates, so they are identifiable in the Cloudflare dashboard. | `string` | `"terraform"` | no |
| <a name="input_rate_limit_rules"></a> [rate\_limit\_rules](#input\_rate\_limit\_rules) | Rate limiting rules, keyed by a stable identifier. These become an `http_ratelimit` ruleset, which is the<br/>current Cloudflare rate limiting product. The deprecated per zone rate limits live in `modules/rate-limit`.<br/><br/>`characteristics` is what the counter is keyed on, for example `["ip.src", "cf.colo.id"]`. Cloudflare<br/>requires `cf.colo.id` in the set on most plans. | <pre>map(object({<br/>    expression  = string<br/>    period      = number<br/>    action      = optional(string, "block")<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>    ref         = optional(string)<br/>    priority    = optional(number, 1000)<br/><br/>    characteristics     = optional(list(string), ["ip.src", "cf.colo.id"])<br/>    requests_per_period = optional(number)<br/>    score_per_period    = optional(number)<br/><br/>    counting_expression        = optional(string)<br/>    mitigation_timeout         = optional(number)<br/>    requests_to_origin         = optional(bool)<br/>    score_response_header_name = optional(string)<br/><br/>    response = optional(object({<br/>      content      = string<br/>      content_type = string<br/>      status_code  = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID the WAF baseline is applied to. Required unless the module is disabled. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bot_management"></a> [bot\_management](#output\_bot\_management) | The full cloudflare\_bot\_management object, or null when bot management is not managed. |
| <a name="output_bot_management_id"></a> [bot\_management\_id](#output\_bot\_management\_id) | Identifier of the bot management configuration, or null when bot management is not managed. |
| <a name="output_custom_rule_order"></a> [custom\_rule\_order](#output\_custom\_rule\_order) | Custom rule keys in the order they were emitted into the ruleset. |
| <a name="output_custom_ruleset"></a> [custom\_ruleset](#output\_custom\_ruleset) | The full cloudflare\_ruleset object for the custom WAF phase, or null when it was not created. |
| <a name="output_custom_ruleset_id"></a> [custom\_ruleset\_id](#output\_custom\_ruleset\_id) | ID of the http\_request\_firewall\_custom entry point ruleset, or null when there are no custom rules. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_managed_ruleset"></a> [managed\_ruleset](#output\_managed\_ruleset) | The full cloudflare\_ruleset object for the managed WAF phase, or null when it was not created. |
| <a name="output_managed_ruleset_id"></a> [managed\_ruleset\_id](#output\_managed\_ruleset\_id) | ID of the http\_request\_firewall\_managed entry point ruleset, or null when managed rulesets are not deployed. |
| <a name="output_managed_ruleset_rule_order"></a> [managed\_ruleset\_rule\_order](#output\_managed\_ruleset\_rule\_order) | Managed ruleset keys in the order they were emitted into the ruleset. |
| <a name="output_rate_limit_rule_order"></a> [rate\_limit\_rule\_order](#output\_rate\_limit\_rule\_order) | Rate limit rule keys in the order they were emitted into the ruleset. |
| <a name="output_rate_limit_ruleset"></a> [rate\_limit\_ruleset](#output\_rate\_limit\_ruleset) | The full cloudflare\_ruleset object for the rate limiting phase, or null when it was not created. |
| <a name="output_rate_limit_ruleset_id"></a> [rate\_limit\_ruleset\_id](#output\_rate\_limit\_ruleset\_id) | ID of the http\_ratelimit entry point ruleset, or null when there are no rate limit rules. |
<!-- END_TF_DOCS -->

---

## License

Apache 2.0. See [LICENSE](LICENSE).

Maintained by [CloudDrove](https://clouddrove.com) and [Cloud Wizz](https://github.com/cloud-wizz).
