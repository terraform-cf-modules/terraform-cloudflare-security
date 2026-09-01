variable "enabled" {
  description = "Whether to create the widgets. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Turnstile widgets."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "widgets" {
  description = "Turnstile widgets to create, keyed by a stable identifier."

  type = map(object({
    name    = string
    domains = list(string)
    mode    = optional(string, "managed")

    bot_fight_mode  = optional(bool)
    clearance_level = optional(string)
    ephemeral_id    = optional(bool)
    offlabel        = optional(bool)
    region          = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for w in values(var.widgets) : contains(["non-interactive", "invisible", "managed"], w.mode)])
    error_message = "Each widget mode must be one of non-interactive, invisible, managed."
  }

  validation {
    condition = alltrue([
      for w in values(var.widgets) :
      w.clearance_level == null || contains(["no_clearance", "jschallenge", "managed", "interactive"], coalesce(w.clearance_level, "no_clearance"))
    ])
    error_message = "Each widget clearance_level must be one of no_clearance, jschallenge, managed, interactive."
  }

  validation {
    condition = alltrue([
      for w in values(var.widgets) :
      w.region == null || contains(["world", "china"], coalesce(w.region, "world"))
    ])
    error_message = "Each widget region must be either world or china."
  }

  validation {
    condition     = alltrue([for w in values(var.widgets) : length(w.domains) > 0])
    error_message = "Each widget must list at least one domain."
  }
}
