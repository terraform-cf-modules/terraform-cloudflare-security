<!-- This file was automatically generated from `README.yaml`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->
<p align="center">
  <img width="1024" height="250" alt="CloudDrove" src="https://clouddrove.s3.ca-central-1.amazonaws.com/Logo/banner.png" />
</p>
<h1 align="center">
    Terraform Cloudflare Security
</h1>

<p align="center" style="font-size: 1.2rem;">
    With our comprehensive DevOps toolkit, streamline operations, automate workflows, enhance collaboration and deploy with confidence.
</p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.12.0-green" alt="Terraform">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-APACHE-blue.svg" alt="Licence">
</a>
<a href="CHANGELOG.md">
  <img src="https://img.shields.io/badge/Changelog-blue" alt="Changelog">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/tf-checks.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/tf-checks.yml/badge.svg" alt="tf-checks">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/tflint.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/tflint.yml/badge.svg" alt="tf-lint">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/checkov.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/checkov.yml/badge.svg" alt="checkov">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/test.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-security/actions/workflows/test.yml/badge.svg" alt="test">
</a>

</p>
<hr>


The Cloudflare security surface as one Terraform module: WAF rulesets, rate limiting, lists, bot management,
the legacy firewall, Turnstile, API Shield and Page Shield. The root module is zone scoped, and the eight
submodules under `modules/` are each usable on their own.

The baseline is the opinion. Give the root module a zone ID and nothing else and it deploys the Cloudflare
Managed Ruleset and the Cloudflare OWASP Core Ruleset into the `http_request_firewall_managed` phase, which
is a defensible starting posture for any zone. Add `custom_rules` or `rate_limit_rules` and it builds the
`http_request_firewall_custom` and `http_ratelimit` phases alongside, taking evaluation order from an
explicit `priority` and then from the map key, never from map iteration order. A phase entry point is
created only when there is something to put in it, because an empty entry point ruleset does not add
nothing, it takes ownership of the phase and clears whatever was there.

`cloudflare_ruleset` is the most complex resource in the provider: one flat `action_parameters` object with
roughly ninety optional attributes whose legality depends on the rule action and the ruleset phase, and raw
generated resource blocks give you none of that back. `modules/ruleset` types the subset used by the
security, transform, redirect, config and logging phases and validates the combinations at plan time.
[`docs/architecture.md`](docs/architecture.md) lists exactly which shapes are supported and which are not.

Two submodules exist for migration rather than for new work. Cloudflare has deprecated the rate limiting,
filters and firewall rules APIs in favour of the Ruleset Engine, and the provider warns on every plan that
touches them, so `modules/rate-limit` and `modules/firewall-legacy` are here to adopt an existing estate and
move it into rulesets, not to start from. New work belongs in a ruleset. Every module targets Cloudflare
provider v5, which was regenerated from the OpenAPI spec in v5.0.0 with most resources renamed, so check
resource names and attributes against the current provider documentation rather than against older examples.

### Things worth knowing before you apply

| Behaviour | What it means for you |
|-----------|-----------------------|
| One entry point ruleset per zone per phase | Two module instances targeting the same zone and phase fight over one object. Give each zone and phase a single owner. |
| Rule order comes from `priority`, then the map key | Never from map order. Use round numbers with gaps so a later insert does not renumber everything. |
| A list reference creates no Terraform dependency | `ip.src in $office_ips` is just a string, so Terraform cannot see the list behind it. Create lists first with `modules/list`, which is account scoped. |
| Bot management and content scanning are zone settings, not objects | Destroying them stops Terraform managing the setting rather than turning the feature off. |
| Managed ruleset IDs are Cloudflare-published values | The defaults in `var.managed_rulesets` are Cloudflare's published IDs for the Cloudflare Managed Ruleset and the OWASP Core Ruleset, not values from the provider schema. Confirm them for your account with `GET /zones/{zone_id}/rulesets` before relying on them. |
| `modules/rate-limit` and `modules/firewall-legacy` are deprecated by Cloudflare | Included for migration off the old APIs. Do not build new rules on them. |


## Prerequisites and Providers

This table contains both Prerequisites and Providers:

| Description | Name | Version |
|-------------|------|---------|
| Prerequisite | Terraform | >= 1.12.0 |
| Prerequisite | OpenTofu | >= 1.12.0 |
| Provider | cloudflare | ~> 5.24 |

---


## 🧩 Submodules

Each submodule is separately addressable with the double slash source syntax, so you can take only the piece you need instead of the whole root module.

| Submodule | Source | Description |
|-----------|--------|-------------|
| [`ruleset`](modules/ruleset) | `terraform-cf-modules/security/cloudflare//modules/ruleset` | A `cloudflare_ruleset` in any supported phase, with typed `action_parameters` for the security, transform, redirect, config and logging phases. The building block the root module is made of. |
| [`list`](modules/list) | `terraform-cf-modules/security/cloudflare//modules/list` | Account scoped IP, ASN, hostname and redirect lists (`cloudflare_list`, `cloudflare_list_item`), inline or as individual members. |
| [`bot-management`](modules/bot-management) | `terraform-cf-modules/security/cloudflare//modules/bot-management` | Zone bot management settings (`cloudflare_bot_management`), covering Bot Fight Mode, Super Bot Fight Mode and Enterprise fields. |
| [`turnstile`](modules/turnstile) | `terraform-cf-modules/security/cloudflare//modules/turnstile` | Turnstile widgets (`cloudflare_turnstile_widget`) and their site and secret keys. |
| [`api-shield`](modules/api-shield) | `terraform-cf-modules/security/cloudflare//modules/api-shield` | API Shield configuration, operations, schemas and schema validation settings. |
| [`page-shield`](modules/page-shield) | `terraform-cf-modules/security/cloudflare//modules/page-shield` | Page Shield policies plus content scanning and its custom expressions. |
| [`rate-limit`](modules/rate-limit) | `terraform-cf-modules/security/cloudflare//modules/rate-limit` | Legacy per zone rate limits (`cloudflare_rate_limit`). Deprecated by Cloudflare, for migration only. |
| [`firewall-legacy`](modules/firewall-legacy) | `terraform-cf-modules/security/cloudflare//modules/firewall-legacy` | Legacy filters, firewall rules, access rules, user agent blocking and zone lockdowns. Deprecated by Cloudflare, for migration only. |

---


## 🚀 Usage

### The baseline

A zone ID and nothing else deploys the Cloudflare Managed Ruleset and the OWASP Core Ruleset. This is
[`examples/basic`](examples/basic).

```hcl
module "security" {
  source  = "terraform-cf-modules/security/cloudflare"
  version = "~> 0.1"

  zone_id = var.zone_id
}
```

### The baseline plus zone specific rules

Managed rulesets with category overrides, custom WAF rules ordered by `priority`, a rate limit and bot
management. [`examples/complete`](examples/complete) turns on every optional feature.

```hcl
module "security" {
  source  = "terraform-cf-modules/security/cloudflare"
  version = "~> 0.1"

  zone_id     = var.zone_id
  name_prefix = "platform"

  # Confirm these IDs for your account with GET /zones/{zone_id}/rulesets.
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

  # Evaluation order comes from priority, not from position in the map.
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
      characteristics     = ["ip.src", "cf.colo.id"]
    }
  }

  bot_management = {
    enable_js          = true
    ai_bots_protection = "block"
  }
}
```

### A single building block

`modules/ruleset` reaches the phases the root module does not model, for example response header hardening.
[`examples/ruleset-phases`](examples/ruleset-phases) builds one ruleset per phase this way.

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

A `wrappers/` module is also published for callers that need the same inputs applied across many zones from
one `defaults` and `items` pair.

---


## 📦 Examples

> ⚠️ **Important:** Avoid using the `main` branch directly, as it may include unstable changes. Always use stable [release versions](https://github.com/terraform-cf-modules/terraform-cloudflare-security/releases).

Explore real-world usage scenarios and implementation patterns in the [`examples/`](./examples/) directory.

---


## 📥 Inputs and Outputs

Detailed input variables and output values are documented for easier integration and day-to-day usage.

📘 [View full documentation](docs/io.md)

---


## 📝 Changelog

Track module updates, improvements, and breaking changes across versions.

📌 [View Changelog](CHANGELOG.md)

---


## ✨ Contributors

Big thanks to our contributors for elevating our project with their dedication and expertise!

<div align="center">
  <a href="https://github.com/terraform-cf-modules/terraform-cloudflare-security/graphs/contributors" title="Contributors">
    <img src="https://contrib.rocks/image?repo=terraform-cf-modules/terraform-cloudflare-security" />
  </a>
</div>

All contributors must follow the [Conventional Commits](https://www.conventionalcommits.org) specification for commit messages.

---


## 🚀 Our Accomplishment

We maintain Terraform modules across AWS, Azure, Google Cloud, DigitalOcean, Hetzner Cloud and Cloudflare 🙌.

- [**Terraform Module Registry**](https://registry.terraform.io/namespaces/terraform-cf-modules): Discover our Cloudflare modules here.
- [**Full module catalog**](https://github.com/clouddrove/toc): Every CloudDrove module and submodule, across every cloud.

---

## Notes

- Do not use the `main` branch for production deployments.
- Always reference a stable version using Git tags or official releases.
- Using tagged versions ensures consistency, stability, and reproducible deployments.

---

## Feedback

Report issues or request features on [GitHub](https://github.com/terraform-cf-modules/terraform-cloudflare-security/issues), or write to [business@clouddrove.com](mailto:business@clouddrove.com).

## About us

At [CloudDrove](https://clouddrove.com), we build reliable, secure and cost efficient cloud native solutions. Join our [Slack community](https://www.launchpass.com/devops-talks).
