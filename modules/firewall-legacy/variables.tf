variable "enabled" {
  description = "Whether to create the resources. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID. Only used for account scoped IP access rules; everything else here is zone scoped."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID that owns the filters, firewall rules, user agent blocking rules and zone lockdowns."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "filters" {
  description = "Standalone `cloudflare_filter` expressions, keyed by a stable identifier. A filter created here can be reused by more than one firewall rule."

  type = map(object({
    expression  = string
    description = optional(string)
    paused      = optional(bool)
    ref         = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for f in values(var.filters) : length(trimspace(f.expression)) > 0])
    error_message = "Each filter expression must be a non empty Cloudflare Rules language expression."
  }
}

variable "firewall_rules" {
  description = <<-EOT
    Legacy firewall rules, keyed by a stable identifier. Each rule owns its filter inline, which is how the v5
    provider models the resource: `cloudflare_firewall_rule.filter` is a nested object, not a filter ID.
  EOT

  type = map(object({
    filter = object({
      expression  = string
      description = optional(string)
      paused      = optional(bool)
      ref         = optional(string)
    })
    action = object({
      mode    = optional(string, "block")
      timeout = optional(number)
      response = optional(object({
        body         = optional(string)
        content_type = optional(string)
      }))
    })
  }))
  default = {}

  # The provider schema description for cloudflare_firewall_rule.action.mode is shared with the rate limiting
  # action and lists only simulate, ban, challenge, js_challenge, managed_challenge. The Firewall Rules API
  # itself also takes allow, block, log and bypass, and refusing those would make an existing estate
  # unimportable, so both sets are accepted here.
  validation {
    condition = alltrue([
      for r in values(var.firewall_rules) : contains([
        "simulate",
        "ban",
        "challenge",
        "js_challenge",
        "managed_challenge",
        "allow",
        "block",
        "log",
        "bypass",
      ], r.action.mode)
    ])
    error_message = "Each firewall rule action.mode must be one of simulate, ban, challenge, js_challenge, managed_challenge, allow, block, log, bypass."
  }

  validation {
    condition     = alltrue([for r in values(var.firewall_rules) : length(trimspace(r.filter.expression)) > 0])
    error_message = "Each firewall rule filter expression must be a non empty Cloudflare Rules language expression."
  }
}

variable "access_rules" {
  description = "IP access rules, keyed by a stable identifier. Scoped to the zone when `zone_id` is set and to the account otherwise."

  type = map(object({
    mode = string
    configuration = object({
      target = string
      value  = string
    })
    notes = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.access_rules) :
      contains(["block", "challenge", "whitelist", "js_challenge", "managed_challenge"], r.mode)
    ])
    error_message = "Each access rule mode must be one of block, challenge, whitelist, js_challenge, managed_challenge."
  }

  validation {
    condition = alltrue([
      for r in values(var.access_rules) :
      contains(["ip", "ip6", "ip_range", "asn", "country"], r.configuration.target)
    ])
    error_message = "Each access rule configuration.target must be one of ip, ip6, ip_range, asn, country."
  }
}

variable "user_agent_blocking_rules" {
  description = "User agent blocking rules, keyed by a stable identifier. Each rule matches one exact User-Agent header value."

  type = map(object({
    mode        = string
    value       = string
    description = optional(string)
    paused      = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.user_agent_blocking_rules) :
      contains(["block", "challenge", "whitelist", "js_challenge", "managed_challenge"], r.mode)
    ])
    error_message = "Each user agent blocking rule mode must be one of block, challenge, whitelist, js_challenge, managed_challenge."
  }

  validation {
    condition     = alltrue([for r in values(var.user_agent_blocking_rules) : length(trimspace(r.value)) > 0])
    error_message = "Each user agent blocking rule value must be a non empty User-Agent string to match exactly."
  }
}

variable "zone_lockdowns" {
  description = "Zone lockdown rules, keyed by a stable identifier. Each rule restricts a set of URLs to a set of IP addresses or ranges."

  type = map(object({
    urls = list(string)
    configurations = list(object({
      target = string
      value  = string
    }))
    description = optional(string)
    paused      = optional(bool)
    priority    = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for l in values(var.zone_lockdowns) : alltrue([
        for c in l.configurations : contains(["ip", "ip_range"], c.target)
      ])
    ])
    error_message = "Each zone lockdown configuration target must be either ip or ip_range."
  }

  validation {
    condition     = alltrue([for l in values(var.zone_lockdowns) : length(l.urls) > 0 && length(l.configurations) > 0])
    error_message = "Each zone lockdown must list at least one URL and at least one IP configuration."
  }
}
