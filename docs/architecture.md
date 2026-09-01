# Architecture

This repository is one root module plus eight building blocks.

The root module encodes an opinion: a zone gets Cloudflare's managed rulesets deployed into the managed WAF
phase, its own rules in the custom WAF phase, and rate limiting in the rate limit phase, each as a separate
entry point ruleset, with rule order derived from an explicit priority rather than from map iteration. That
baseline, and the ordering discipline behind it, is the part that a generated pile of raw resource blocks does
not give you.

Everything else is a building block that composes.

## Resource map

| Terraform resource | Cloudflare object | Created by |
|--------------------|-------------------|------------|
| `cloudflare_ruleset` | Ruleset in one phase, with its rules | `modules/ruleset`, called three times by the root |
| `cloudflare_rate_limit` | Legacy zone rate limit (deprecated) | `modules/rate-limit` |
| `cloudflare_list` | Account list of IPs, ASNs, hostnames or redirects | `modules/list` |
| `cloudflare_list_item` | One member of a list | `modules/list` |
| `cloudflare_bot_management` | Zone bot detection settings | `modules/bot-management`, called by the root |
| `cloudflare_filter` | Legacy filter expression (deprecated) | `modules/firewall-legacy` |
| `cloudflare_firewall_rule` | Legacy firewall rule (deprecated) | `modules/firewall-legacy` |
| `cloudflare_access_rule` | IP access rule | `modules/firewall-legacy` |
| `cloudflare_user_agent_blocking_rule` | User agent block | `modules/firewall-legacy` |
| `cloudflare_zone_lockdown` | Zone lockdown | `modules/firewall-legacy` |
| `cloudflare_turnstile_widget` | Turnstile widget | `modules/turnstile` |
| `cloudflare_api_shield` | API client identification | `modules/api-shield` |
| `cloudflare_api_shield_operation` | Tracked API endpoint | `modules/api-shield` |
| `cloudflare_api_shield_schema` | Uploaded OpenAPI schema, v1 (deprecated) | `modules/api-shield` |
| `cloudflare_api_shield_operation_schema_validation_settings` | Per operation mitigation, v1 (deprecated) | `modules/api-shield` |
| `cloudflare_schema_validation_operation_settings` | Per operation mitigation, v2 | `modules/api-shield` |
| `cloudflare_schema_validation_schemas` | Uploaded OpenAPI schema, v2 | `modules/api-shield` |
| `cloudflare_schema_validation_settings` | Zone schema validation settings | `modules/api-shield` |
| `cloudflare_page_shield_policy` | Page Shield policy | `modules/page-shield` |
| `cloudflare_content_scanning` | Zone content scanning switch | `modules/page-shield` |
| `cloudflare_content_scanning_expression` | Custom upload scan expression | `modules/page-shield` |

## What the root module composes

```
root
├── modules/ruleset          phase = http_request_firewall_managed   (var.managed_rulesets)
├── modules/ruleset          phase = http_request_firewall_custom    (var.custom_rules)
├── modules/ruleset          phase = http_ratelimit                  (var.rate_limit_rules)
└── modules/bot-management                                           (var.bot_management)
```

Each is created only when there is something to put in it. That matters more than it sounds: an entry point
ruleset is not additive. Creating an empty one for a phase takes ownership of that phase and clears whatever
was there, including rules Cloudflare auto-migrated from the legacy firewall. So `custom_rules = {}` creates no
ruleset at all rather than an empty one, and `bot_management = null` leaves the zone setting untouched.

## Scope

| Module | Anchor |
|--------|--------|
| root | `zone_id` (required when enabled); `account_id` accepted but unused |
| `modules/ruleset` | exactly one of `account_id` or `zone_id` |
| `modules/list` | `account_id` |
| `modules/turnstile` | `account_id` |
| `modules/rate-limit`, `modules/bot-management`, `modules/api-shield`, `modules/page-shield` | `zone_id` |
| `modules/firewall-legacy` | `zone_id`, plus `account_id` for account scoped IP access rules |

Lists are account scoped even when a single zone uses them, which is why a zone scoped WAF rule that says
`ip.src in $office_ips` depends on a resource created with a different anchor.

## Rule ordering

Cloudflare evaluates a ruleset's rules in list order, and the provider takes them as a list. A list in HCL is
the wrong shape for configuration that changes: inserting a rule at the top renumbers every index after it and
produces a diff on rules nobody touched.

So `rules` is a map, and order is derived:

1. ascending `priority` (default `1000`);
2. then map key, alphabetically.

Both are stable, so the same configuration always produces the same list, and the `rule_order` output shows the
result without applying. Use round numbers with gaps so a rule can be inserted later without renumbering.

## Which `action_parameters` shapes are supported

`cloudflare_ruleset.rules[].action_parameters` is a single flat object with roughly ninety optional attributes.
Which are legal depends on the rule's `action` and the ruleset's `phase`; the provider does not express that
relationship in the schema, and neither can a Terraform object type.

`modules/ruleset` types the subset used by the security, transform, redirect, config and logging phases:

| Action | Attributes |
|--------|-----------|
| `execute` | `id`, `overrides` (`action`, `enabled`, `sensitivity_level`, `categories[]`, `rules[]`), `matched_data.public_key` |
| `skip` | `ruleset`, `rulesets`, `phases`, `products`, `rules` |
| `block` | `response` |
| `serve_error` | `asset_name`, `content`, `content_type`, `status_code` |
| `redirect` | `from_value`, `from_list` |
| `rewrite` | `uri.path`, `uri.query`, `headers` |
| `score` | `increment` |
| `compress_response` | `algorithms` |
| `set_config` | `automatic_https_rewrites`, `autominify`, `bic`, `disable_apps`, `disable_rum`, `disable_zaraz`, `email_obfuscation`, `fonts`, `hotlink_protection`, `mirage`, `opportunistic_encryption`, `polish`, `rocket_loader`, `security_level`, `server_side_excludes`, `ssl`, `sxg`, `request_body_buffering`, `response_body_buffering` |
| `log_custom_field` | `cookie_fields`, `request_fields`, `transformed_request_fields`, `response_fields`, `raw_response_fields` |

**Not** supported, and not planned here: the caching shapes (`browser_ttl`, `edge_ttl`, `cache`, `cache_key`,
`cache_reserve`, `serve_stale`, `additional_cacheable_ports`, `origin_cache_control`,
`origin_error_page_passthru`, `respect_strong_etags`, `read_timeout`, `vary`, `set_cache_tags` values, and the
cache-control atoms `max_age`, `no_cache`, `no_store`, `private`, `public`, `immutable`, `must_revalidate`,
`must_understand`, `no_transform`, `proxy_revalidate`, `s_maxage`, `stale_if_error`, `stale_while_revalidate`)
and the origin routing shapes (`origin`, `host_header`, `sni`). Those belong to a cache or performance module,
not to a security one.

The root module's `custom_rules` types a narrower subset again, because the custom firewall phase only accepts
a handful of actions. When a rule needs something outside that, call `modules/ruleset` directly; the two
compose, they do not conflict, as long as they do not target the same zone and phase.

Two convenience differences from the raw schema, both mechanical:

- `algorithms`, `cookie_fields`, `request_fields` and `transformed_request_fields` take plain lists of strings
  and are wrapped in the provider's `{ name = ... }` objects internally.
- `headers` is a map keyed by header name rather than a map of objects repeating the name.

## Ordering and dependencies

- Rule expressions referencing a list (`ip.src in $office_ips`) have **no** implicit dependency on the list
  resource, because the reference is a string, not an attribute. Create the list in an earlier apply, or accept
  that the first apply may fail until the list exists. This is why `modules/list` is separate from the root.
- `cloudflare_content_scanning_expression` carries an explicit `depends_on` for `cloudflare_content_scanning`:
  Cloudflare rejects custom scan expressions while content scanning is off, and nothing in the resource
  arguments expresses that.
- `cloudflare_list_item` depends on `cloudflare_list` through the `list_id` attribute, so ordering there is
  implicit and correct.
- `cloudflare_api_shield_operation` must exist before its schema validation settings; that dependency is
  implicit through `operation_id`.
- Nothing else in this repository needs a `depends_on`.

## Known provider quirks

- **One entry point ruleset per zone per phase.** Two module instances targeting the same zone and phase fight
  over one object and produce a permanent diff. Split by phase, not by team.
- **`cloudflare_filter` and `cloudflare_content_scanning_expression` are modelled on bulk endpoints.** Both
  have a required `body` list *and* the same fields at the top level. The modules write one element per
  resource so a change to one does not rewrite the rest.
- **`cloudflare_firewall_rule.filter` is an inline object, not a filter ID.** The v4 pattern of creating a
  filter and referencing `filter_id` is gone.
- **`cloudflare_firewall_rule` marks `priority`, `paused`, `ref`, `products` and `description` computed only**,
  so they cannot be set from Terraform.
- **`cloudflare_firewall_rule.action.mode`'s schema description is copied from the rate limiting action** and
  lists only `simulate`, `ban`, `challenge`, `js_challenge`, `managed_challenge`. The API also takes `allow`,
  `block`, `log` and `bypass`, so `modules/firewall-legacy` validates against both sets.
- **`cloudflare_rate_limit.bypass` is computed only** and cannot be set.
- **Zone settings pretending to be resources.** `cloudflare_bot_management` and `cloudflare_content_scanning`
  patch an existing zone rather than creating anything. Destroying them stops Terraform managing the setting;
  it does not turn the feature off. Every input on those modules defaults to `null`, meaning "leave alone".
- **Two generations of schema validation.** The provider marks `cloudflare_api_shield_schema` and
  `cloudflare_api_shield_operation_schema_validation_settings` deprecated in favour of
  `cloudflare_schema_validation_schemas` and `cloudflare_schema_validation_operation_settings`.
  `modules/api-shield` defaults to the current pair and keeps the old ones available for adoption.
- **`cloudflare_api_shield_schema.validation_enabled` is the string `"true"` or `"false"`**, while
  `cloudflare_schema_validation_schemas.validation_enabled` is a real bool. Both modules take a bool.
- **Managed ruleset IDs are not in the provider schema.** The `var.managed_rulesets` defaults carry
  Cloudflare's published IDs for the Cloudflare Managed Ruleset and the OWASP Core Ruleset. Confirm them for
  your account with `GET /zones/{zone_id}/rulesets` before relying on them; override the map to change the set.
- **Turnstile `region` is immutable.** Changing it replaces the widget, which changes the sitekey and breaks
  every page embedding it.
- **Plan gating is invisible to Terraform.** Page Shield needs Business, content scanning and API Shield need
  Enterprise, and the bot management fields split across Free, Pro/Business and Enterprise. The provider
  accepts the configuration and the API rejects it at apply.
