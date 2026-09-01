# -----------------------------------------------------------------------------
# Common inputs. Every module in this organisation exposes these.
# -----------------------------------------------------------------------------

variable "enabled" {
  description = "Whether to create the resources managed by this module. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

# The root module is zone scoped and never reads account_id, but every module in this organisation accepts the
# same two anchors so that a caller can pass one set of variables to all of them, and the integration workflow
# supplies TF_VAR_account_id unconditionally.
# tflint-ignore: terraform_unused_declarations
variable "account_id" {
  description = "Cloudflare account ID. Accepted for interface consistency with the other modules in this organisation and with the account scoped submodules; the root module itself is zone scoped and does not use it."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID the WAF baseline is applied to. Required unless the module is disabled."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }

  validation {
    condition     = var.enabled == false || var.zone_id != null
    error_message = "zone_id is required when the module is enabled. The root module is zone scoped."
  }
}

# -----------------------------------------------------------------------------
# Naming
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix applied to the name of every ruleset this module creates, so they are identifiable in the Cloudflare dashboard."
  type        = string
  default     = "terraform"

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

# -----------------------------------------------------------------------------
# Managed WAF rulesets (phase http_request_firewall_managed)
# -----------------------------------------------------------------------------

variable "managed_rulesets_enabled" {
  description = "Whether to deploy the managed WAF rulesets in var.managed_rulesets. Set to false to keep the input but stop managing the http_request_firewall_managed entry point."
  type        = bool
  default     = true
}

variable "managed_rulesets" {
  description = <<-EOT
    Cloudflare managed rulesets to execute, keyed by a stable identifier.

    `id` is the Cloudflare ruleset ID to run. The defaults deploy the Cloudflare Managed Ruleset and the
    Cloudflare OWASP Core Ruleset, which is the baseline this module exists to encode. The IDs are Cloudflare's
    published managed ruleset IDs, not values from the provider schema; confirm them for your account with
    `GET /zones/{zone_id}/rulesets` before relying on them, and override the map to change the set.

    Set this to `{}` to deploy no managed rulesets while still managing the phase entry point.
  EOT

  type = map(object({
    id          = string
    expression  = optional(string, "true")
    description = optional(string)
    enabled     = optional(bool, true)
    priority    = optional(number, 1000)

    overrides = optional(object({
      action            = optional(string)
      enabled           = optional(bool)
      sensitivity_level = optional(string)
      categories = optional(list(object({
        category          = string
        action            = optional(string)
        enabled           = optional(bool)
        sensitivity_level = optional(string)
      })))
      rules = optional(list(object({
        id                = string
        action            = optional(string)
        enabled           = optional(bool)
        score_threshold   = optional(number)
        sensitivity_level = optional(string)
      })))
    }))

    matched_data_public_key = optional(string)
  }))

  default = {
    cloudflare_managed = {
      id          = "efb7b8c949ac4650a09736fc376e9aee"
      description = "Cloudflare Managed Ruleset"
      priority    = 10
    }
    owasp_core = {
      id          = "4814384a9e5d4991b9815dcfc25d2f1f"
      description = "Cloudflare OWASP Core Ruleset"
      priority    = 20
    }
  }

  validation {
    condition     = alltrue([for r in values(var.managed_rulesets) : can(regex("^[0-9a-f]{32}$", r.id))])
    error_message = "Each managed ruleset id must be a 32 character lowercase hexadecimal Cloudflare ruleset ID."
  }

  validation {
    condition = alltrue([
      for r in values(var.managed_rulesets) :
      try(r.overrides.action, null) == null || contains(
        ["block", "challenge", "js_challenge", "log", "managed_challenge"],
        try(r.overrides.action, "")
      )
    ])
    error_message = "A managed ruleset overrides.action must be one of block, challenge, js_challenge, log, managed_challenge."
  }
}

# -----------------------------------------------------------------------------
# Custom WAF rules (phase http_request_firewall_custom)
# -----------------------------------------------------------------------------

variable "custom_rules" {
  description = <<-EOT
    Zone specific WAF rules, keyed by a stable identifier. Emitted in ascending `priority` order, then by key.

    This is the opinionated subset of the ruleset engine that a custom firewall phase actually uses. For
    transform, redirect, cache or logging phases, or for an action parameter shape not listed here, call
    `modules/ruleset` directly.
  EOT

  type = map(object({
    expression  = string
    action      = optional(string, "block")
    description = optional(string)
    enabled     = optional(bool, true)
    ref         = optional(string)
    priority    = optional(number, 1000)

    logging = optional(object({
      enabled = bool
    }))

    exposed_credential_check = optional(object({
      username_expression = string
      password_expression = string
    }))

    action_parameters = optional(object({
      # action = "block"
      response = optional(object({
        content      = string
        content_type = string
        status_code  = number
      }))

      # action = "skip"
      ruleset  = optional(string)
      rulesets = optional(list(string))
      phases   = optional(list(string))
      products = optional(list(string))
      rules    = optional(map(list(string)))

      # action = "execute"
      id = optional(string)
      overrides = optional(object({
        action            = optional(string)
        enabled           = optional(bool)
        sensitivity_level = optional(string)
        categories = optional(list(object({
          category          = string
          action            = optional(string)
          enabled           = optional(bool)
          sensitivity_level = optional(string)
        })))
        rules = optional(list(object({
          id                = string
          action            = optional(string)
          enabled           = optional(bool)
          score_threshold   = optional(number)
          sensitivity_level = optional(string)
        })))
      }))
      matched_data = optional(object({
        public_key = string
      }))

      # action = "redirect"
      from_value = optional(object({
        preserve_query_string = optional(bool)
        status_code           = optional(number)
        target_url = object({
          value      = optional(string)
          expression = optional(string)
        })
      }))
      from_list = optional(object({
        key  = string
        name = string
      }))

      # action = "score"
      increment = optional(number)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.custom_rules) : contains([
        "block",
        "challenge",
        "execute",
        "force_connection_close",
        "js_challenge",
        "log",
        "managed_challenge",
        "redirect",
        "score",
        "skip",
      ], r.action)
    ])
    error_message = "Each custom rule action must be one of block, challenge, execute, force_connection_close, js_challenge, log, managed_challenge, redirect, score, skip. Other actions belong to other phases; call modules/ruleset for those."
  }

  validation {
    condition     = alltrue([for r in values(var.custom_rules) : length(trimspace(r.expression)) > 0])
    error_message = "Each custom rule expression must be a non empty Cloudflare Rules language expression."
  }

  validation {
    condition = alltrue([
      for r in values(var.custom_rules) :
      r.action != "skip" || (
        r.action_parameters != null && length(compact([
          try(r.action_parameters.ruleset, null),
          try(r.action_parameters.rulesets, null) == null ? null : "rulesets",
          try(r.action_parameters.phases, null) == null ? null : "phases",
          try(r.action_parameters.products, null) == null ? null : "products",
          try(r.action_parameters.rules, null) == null ? null : "rules",
        ])) > 0
      )
    ])
    error_message = "A rule with action \"skip\" must say what to skip through action_parameters: one of ruleset, rulesets, phases, products or rules."
  }
}

# -----------------------------------------------------------------------------
# Rate limiting (phase http_ratelimit)
# -----------------------------------------------------------------------------

variable "rate_limit_rules" {
  description = <<-EOT
    Rate limiting rules, keyed by a stable identifier. These become an `http_ratelimit` ruleset, which is the
    current Cloudflare rate limiting product. The deprecated per zone rate limits live in `modules/rate-limit`.

    `characteristics` is what the counter is keyed on, for example `["ip.src", "cf.colo.id"]`. Cloudflare
    requires `cf.colo.id` in the set on most plans.
  EOT

  type = map(object({
    expression  = string
    period      = number
    action      = optional(string, "block")
    description = optional(string)
    enabled     = optional(bool, true)
    ref         = optional(string)
    priority    = optional(number, 1000)

    characteristics     = optional(list(string), ["ip.src", "cf.colo.id"])
    requests_per_period = optional(number)
    score_per_period    = optional(number)

    counting_expression        = optional(string)
    mitigation_timeout         = optional(number)
    requests_to_origin         = optional(bool)
    score_response_header_name = optional(string)

    response = optional(object({
      content      = string
      content_type = string
      status_code  = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.rate_limit_rules) : contains([
        "block",
        "challenge",
        "js_challenge",
        "log",
        "managed_challenge",
      ], r.action)
    ])
    error_message = "Each rate limit rule action must be one of block, challenge, js_challenge, log, managed_challenge."
  }

  validation {
    condition = alltrue([
      for r in values(var.rate_limit_rules) :
      contains([10, 60, 120, 300, 600, 3600], r.period)
    ])
    error_message = "Each rate limit rule period must be one of 10, 60, 120, 300, 600, 3600 seconds, the values Cloudflare accepts."
  }

  validation {
    condition = alltrue([
      for r in values(var.rate_limit_rules) :
      (r.requests_per_period != null) != (r.score_per_period != null)
    ])
    error_message = "Each rate limit rule must set exactly one of requests_per_period or score_per_period."
  }

  validation {
    condition     = alltrue([for r in values(var.rate_limit_rules) : length(r.characteristics) > 0])
    error_message = "Each rate limit rule must have at least one counting characteristic."
  }
}

# -----------------------------------------------------------------------------
# Bot management
# -----------------------------------------------------------------------------

variable "bot_management" {
  description = <<-EOT
    Zone bot management settings. Leave null to not manage them at all.

    Which fields the zone accepts depends on its plan: `fight_mode` is Free, the `sbfm_*` fields are Super Bot
    Fight Mode on Pro and Business, and the rest belong to Enterprise Bot Management. Any field left null is
    left exactly as the zone already has it.
  EOT

  type = object({
    fight_mode         = optional(bool)
    optimize_wordpress = optional(bool)

    sbfm_definitely_automated       = optional(string)
    sbfm_likely_automated           = optional(string)
    sbfm_verified_bots              = optional(string)
    sbfm_static_resource_protection = optional(bool)

    enable_js              = optional(bool)
    auto_update_model      = optional(bool)
    suppress_session_score = optional(bool)
    bm_cookie_enabled      = optional(bool)

    ai_bots_protection      = optional(string)
    crawler_protection      = optional(string)
    content_bots_protection = optional(string)
    cf_robots_variant       = optional(string)
    is_robots_txt_managed   = optional(bool)
  })
  default = null
}
