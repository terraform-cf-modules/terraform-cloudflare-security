variable "enabled" {
  description = "Whether to create the ruleset. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID for an account scoped ruleset. Set exactly one of account_id or zone_id."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID for a zone scoped ruleset. Set exactly one of account_id or zone_id."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "name" {
  description = "Human readable name of the ruleset."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Informative description of the ruleset."
  type        = string
  default     = null
}

variable "kind" {
  description = "Kind of the ruleset. Entry point rulesets attached to a zone use `zone`, account entry points use `root`, and reusable rulesets use `custom`."
  type        = string
  default     = "zone"

  validation {
    condition     = contains(["managed", "custom", "root", "zone"], var.kind)
    error_message = "kind must be one of managed, custom, root, zone."
  }
}

variable "phase" {
  description = "Phase the ruleset runs in. Security phases are http_request_firewall_custom, http_request_firewall_managed, http_ratelimit, http_response_firewall_managed and http_request_sbfm."
  type        = string

  validation {
    condition = contains([
      "ddos_l4",
      "ddos_l7",
      "http_config_settings",
      "http_custom_errors",
      "http_log_custom_fields",
      "http_ratelimit",
      "http_request_cache_settings",
      "http_request_dynamic_redirect",
      "http_request_firewall_custom",
      "http_request_firewall_managed",
      "http_request_late_transform",
      "http_request_origin",
      "http_request_redirect",
      "http_request_sanitize",
      "http_request_sbfm",
      "http_request_transform",
      "http_response_cache_settings",
      "http_response_compression",
      "http_response_firewall_managed",
      "http_response_headers_transform",
      "magic_transit",
      "magic_transit_ids_managed",
      "magic_transit_managed",
      "magic_transit_ratelimit",
    ], var.phase)
    error_message = "phase must be one of the phases accepted by cloudflare_ruleset. See the module README for the full list."
  }
}

variable "rules" {
  description = <<-EOT
    Rules in the ruleset, keyed by a stable identifier. Rules are emitted in ascending `priority` order and then
    alphabetically by key, so evaluation order stays deterministic when keys are added or removed.

    `action_parameters` covers the shapes used by the security, transform, redirect, config and logging phases.
    The caching and origin shapes are deliberately not modelled; see the module README.
  EOT

  type = map(object({
    expression  = string
    action      = string
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

    ratelimit = optional(object({
      characteristics            = list(string)
      period                     = number
      counting_expression        = optional(string)
      mitigation_timeout         = optional(number)
      requests_per_period        = optional(number)
      requests_to_origin         = optional(bool)
      score_per_period           = optional(number)
      score_response_header_name = optional(string)
    }))

    action_parameters = optional(object({
      # action = "execute" -- run a managed ruleset.
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

      # action = "skip"
      ruleset  = optional(string)
      rulesets = optional(list(string))
      phases   = optional(list(string))
      products = optional(list(string))
      rules    = optional(map(list(string)))

      # action = "block" with a custom response.
      response = optional(object({
        content      = string
        content_type = string
        status_code  = number
      }))

      # action = "serve_error"
      asset_name   = optional(string)
      content      = optional(string)
      content_type = optional(string)
      status_code  = optional(number)

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

      # action = "rewrite" in the transform phases.
      uri = optional(object({
        path = optional(object({
          value      = optional(string)
          expression = optional(string)
        }))
        query = optional(object({
          value      = optional(string)
          expression = optional(string)
        }))
      }))
      headers = optional(map(object({
        operation  = string
        value      = optional(string)
        expression = optional(string)
      })))

      # action = "score"
      increment = optional(number)

      # action = "compress_response"
      algorithms = optional(list(string))

      # action = "set_config"
      automatic_https_rewrites = optional(bool)
      autominify = optional(object({
        css  = optional(bool)
        html = optional(bool)
        js   = optional(bool)
      }))
      bic                      = optional(bool)
      disable_apps             = optional(bool)
      disable_rum              = optional(bool)
      disable_zaraz            = optional(bool)
      email_obfuscation        = optional(bool)
      fonts                    = optional(bool)
      hotlink_protection       = optional(bool)
      mirage                   = optional(bool)
      opportunistic_encryption = optional(bool)
      polish                   = optional(string)
      rocket_loader            = optional(bool)
      security_level           = optional(string)
      server_side_excludes     = optional(bool)
      ssl                      = optional(string)
      sxg                      = optional(bool)

      # http_request_sanitize / body buffering.
      request_body_buffering  = optional(string)
      response_body_buffering = optional(string)

      # action = "log_custom_field"
      cookie_fields              = optional(list(string))
      request_fields             = optional(list(string))
      transformed_request_fields = optional(list(string))
      response_fields = optional(list(object({
        name                = string
        preserve_duplicates = optional(bool)
      })))
      raw_response_fields = optional(list(object({
        name                = string
        preserve_duplicates = optional(bool)
      })))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.rules) : contains([
        "block",
        "challenge",
        "compress_response",
        "ddos_dynamic",
        "execute",
        "force_connection_close",
        "js_challenge",
        "log",
        "log_custom_field",
        "managed_challenge",
        "redirect",
        "rewrite",
        "route",
        "score",
        "serve_error",
        "set_cache_control",
        "set_cache_settings",
        "set_cache_tags",
        "set_config",
        "skip",
      ], r.action)
    ])
    error_message = "Each rule action must be one of block, challenge, compress_response, ddos_dynamic, execute, force_connection_close, js_challenge, log, log_custom_field, managed_challenge, redirect, rewrite, route, score, serve_error, set_cache_control, set_cache_settings, set_cache_tags, set_config, skip."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) : length(trimspace(r.expression)) > 0
    ])
    error_message = "Each rule expression must be a non empty Cloudflare Rules language expression."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action != "execute" || (r.action_parameters != null && try(r.action_parameters.id, null) != null)
    ])
    error_message = "A rule with action \"execute\" must set action_parameters.id to the managed ruleset ID to run."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action_parameters == null || try(r.action_parameters.headers, null) == null || alltrue([
        for h in values(coalesce(try(r.action_parameters.headers, null), {})) :
        contains(["add", "set", "remove"], h.operation)
      ])
    ])
    error_message = "Each action_parameters.headers operation must be one of add, set, remove."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action_parameters == null || try(r.action_parameters.security_level, null) == null ||
      contains(["off", "essentially_off", "low", "medium", "high", "under_attack"], try(r.action_parameters.security_level, ""))
    ])
    error_message = "action_parameters.security_level must be one of off, essentially_off, low, medium, high, under_attack."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action_parameters == null || try(r.action_parameters.ssl, null) == null ||
      contains(["off", "flexible", "full", "strict", "origin_pull"], try(r.action_parameters.ssl, ""))
    ])
    error_message = "action_parameters.ssl must be one of off, flexible, full, strict, origin_pull."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action_parameters == null || try(r.action_parameters.products, null) == null || alltrue([
        for p in coalesce(try(r.action_parameters.products, null), []) :
        contains(["bic", "hot", "rateLimit", "securityLevel", "uaBlock", "waf", "zoneLockdown"], p)
      ])
    ])
    error_message = "action_parameters.products entries must be one of bic, hot, rateLimit, securityLevel, uaBlock, waf, zoneLockdown."
  }

  validation {
    condition = alltrue([
      for r in values(var.rules) :
      r.action_parameters == null || try(r.action_parameters.algorithms, null) == null || alltrue([
        for a in coalesce(try(r.action_parameters.algorithms, null), []) :
        contains(["none", "auto", "default", "gzip", "brotli", "zstd"], a)
      ])
    ])
    error_message = "action_parameters.algorithms entries must be one of none, auto, default, gzip, brotli, zstd."
  }
}
