variable "enabled" {
  description = "Whether to create the rate limits. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "Cloudflare zone ID the rate limits belong to."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "rate_limits" {
  description = "Legacy zone rate limits to create, keyed by a stable identifier."

  type = map(object({
    period    = number
    threshold = number

    action = object({
      mode    = optional(string, "simulate")
      timeout = optional(number)
      response = optional(object({
        body         = optional(string)
        content_type = optional(string)
      }))
    })

    match = object({
      request = optional(object({
        url     = optional(string)
        methods = optional(list(string))
        schemes = optional(list(string))
      }))
      response = optional(object({
        origin_traffic = optional(bool)
      }))
      headers = optional(list(object({
        name  = optional(string)
        op    = optional(string)
        value = optional(string)
      })))
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.rate_limits) :
      contains(["simulate", "ban", "challenge", "js_challenge", "managed_challenge"], r.action.mode)
    ])
    error_message = "Each rate limit action.mode must be one of simulate, ban, challenge, js_challenge, managed_challenge."
  }

  validation {
    condition = alltrue([
      for r in values(var.rate_limits) : r.period >= 1 && r.threshold >= 1
    ])
    error_message = "Each rate limit period and threshold must be at least 1."
  }

  validation {
    condition = alltrue([
      for r in values(var.rate_limits) :
      r.match.headers == null || alltrue([
        for h in coalesce(r.match.headers, []) : h.op == null || contains(["eq", "ne"], h.op)
      ])
    ])
    error_message = "Each match.headers op must be either eq or ne."
  }

  validation {
    condition = alltrue([
      for r in values(var.rate_limits) :
      try(r.action.response, null) == null || try(r.action.response.content_type, null) == null ||
      contains(["text/plain", "text/xml", "application/json"], try(r.action.response.content_type, ""))
    ])
    error_message = "action.response.content_type must be one of text/plain, text/xml, application/json."
  }
}
