variable "enabled" {
  description = "Whether to manage bot management for the zone. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "Cloudflare zone ID whose bot management settings are managed."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "fight_mode" {
  description = "Whether to enable Bot Fight Mode. Free plan feature, mutually exclusive with Super Bot Fight Mode and with the Bot Management plan settings."
  type        = bool
  default     = null
}

variable "optimize_wordpress" {
  description = "Whether to optimise Super Bot Fight Mode protections for WordPress."
  type        = bool
  default     = null
}

variable "sbfm_definitely_automated" {
  description = "Super Bot Fight Mode action for definitely automated requests. One of allow, block, managed_challenge."
  type        = string
  default     = null

  validation {
    condition     = var.sbfm_definitely_automated == null || contains(["allow", "block", "managed_challenge"], coalesce(var.sbfm_definitely_automated, "allow"))
    error_message = "sbfm_definitely_automated must be one of allow, block, managed_challenge."
  }
}

variable "sbfm_likely_automated" {
  description = "Super Bot Fight Mode action for likely automated requests. One of allow, block, managed_challenge."
  type        = string
  default     = null

  validation {
    condition     = var.sbfm_likely_automated == null || contains(["allow", "block", "managed_challenge"], coalesce(var.sbfm_likely_automated, "allow"))
    error_message = "sbfm_likely_automated must be one of allow, block, managed_challenge."
  }
}

variable "sbfm_verified_bots" {
  description = "Super Bot Fight Mode action for verified bot requests. One of allow, block."
  type        = string
  default     = null

  validation {
    condition     = var.sbfm_verified_bots == null || contains(["allow", "block"], coalesce(var.sbfm_verified_bots, "allow"))
    error_message = "sbfm_verified_bots must be one of allow, block."
  }
}

variable "sbfm_static_resource_protection" {
  description = "Whether Super Bot Fight Mode also protects static resources."
  type        = bool
  default     = null
}

variable "enable_js" {
  description = "Whether to use lightweight invisible JavaScript detections to improve bot scoring."
  type        = bool
  default     = null
}

variable "auto_update_model" {
  description = "Whether to move automatically to each new Cloudflare bot detection model as it is released."
  type        = bool
  default     = null
}

variable "suppress_session_score" {
  description = "Whether to stop tracking the highest bot score for a session in the bot management cookie."
  type        = bool
  default     = null
}

variable "bm_cookie_enabled" {
  description = "Whether the bot management cookie may be placed on end user devices. Cloudflare defaults this to true."
  type        = bool
  default     = null
}

variable "ai_bots_protection" {
  description = "Rule to block AI scrapers and crawlers. One of block, disabled, only_on_ad_pages."
  type        = string
  default     = null

  validation {
    condition     = var.ai_bots_protection == null || contains(["block", "disabled", "only_on_ad_pages"], coalesce(var.ai_bots_protection, "disabled"))
    error_message = "ai_bots_protection must be one of block, disabled, only_on_ad_pages."
  }
}

variable "crawler_protection" {
  description = "Rule that sends AI scrapers and crawlers into a link maze. One of enabled, disabled."
  type        = string
  default     = null

  validation {
    condition     = var.crawler_protection == null || contains(["enabled", "disabled"], coalesce(var.crawler_protection, "disabled"))
    error_message = "crawler_protection must be one of enabled, disabled."
  }
}

variable "content_bots_protection" {
  description = "Rule to block content bots, meaning automated traffic with low bot scores outside the safe verified categories. One of block, disabled."
  type        = string
  default     = null

  validation {
    condition     = var.content_bots_protection == null || contains(["block", "disabled"], coalesce(var.content_bots_protection, "disabled"))
    error_message = "content_bots_protection must be one of block, disabled."
  }
}

variable "cf_robots_variant" {
  description = "Robots Access Control License variant to publish. One of off, policy_only."
  type        = string
  default     = null

  validation {
    condition     = var.cf_robots_variant == null || contains(["off", "policy_only"], coalesce(var.cf_robots_variant, "off"))
    error_message = "cf_robots_variant must be one of off, policy_only."
  }
}

variable "is_robots_txt_managed" {
  description = "Whether Cloudflare manages robots.txt for the zone, prepending its own directives to any existing file."
  type        = bool
  default     = null
}
