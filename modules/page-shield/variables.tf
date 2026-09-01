variable "enabled" {
  description = "Whether to create the resources. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "Cloudflare zone ID that Page Shield and content scanning are configured on."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "policies" {
  description = <<-EOT
    Page Shield policies, keyed by a stable identifier.

    `expression` selects the requests the policy applies to, in the Cloudflare Rules language. `value` is the
    policy itself: a Content Security Policy directive set for the `allow` and `add_reporting_directives`
    actions, and the set of allowed resources for `log`.
  EOT

  type = map(object({
    description = string
    expression  = string
    value       = string
    action      = optional(string, "log")
    enabled     = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.policies) : contains(["allow", "log", "add_reporting_directives"], p.action)
    ])
    error_message = "Each Page Shield policy action must be one of allow, log, add_reporting_directives."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      length(trimspace(p.expression)) > 0 && length(trimspace(p.value)) > 0
    ])
    error_message = "Each Page Shield policy must set a non empty expression and value."
  }
}

variable "content_scanning" {
  description = "Whether to turn on content scanning for uploads on the zone. Leave null to not manage the setting at all."
  type        = bool
  default     = null
}

variable "content_scanning_expressions" {
  description = <<-EOT
    Custom scan expressions telling content scanning where to find uploaded objects in a request, keyed by a
    stable identifier. Each payload is a Rules language expression such as
    `lookup_json_string(http.request.body.raw, "file")`.

    Requires `content_scanning = true`.
  EOT

  type    = map(string)
  default = {}

  validation {
    condition     = alltrue([for e in values(var.content_scanning_expressions) : length(trimspace(e)) > 0])
    error_message = "Each content scanning expression must be non empty."
  }
}
