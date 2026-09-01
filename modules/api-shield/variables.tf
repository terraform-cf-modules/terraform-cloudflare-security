variable "enabled" {
  description = "Whether to create the resources. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "Cloudflare zone ID that API Shield is configured on."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "auth_id_characteristics" {
  description = <<-EOT
    Fields that identify an API client, used for per client rate thresholds and for endpoint discovery. Setting
    this creates the `cloudflare_api_shield` configuration for the zone; leaving it empty creates nothing.
  EOT

  type = list(object({
    name = string
    type = string
  }))
  default = []

  validation {
    condition     = alltrue([for c in var.auth_id_characteristics : contains(["header", "cookie", "jwt"], c.type)])
    error_message = "Each auth ID characteristic type must be one of header, cookie, jwt."
  }

  validation {
    condition     = alltrue([for c in var.auth_id_characteristics : length(trimspace(c.name)) > 0])
    error_message = "Each auth ID characteristic must name the header, cookie or JWT claim it reads."
  }
}

variable "operations" {
  description = <<-EOT
    API endpoints to track, keyed by a stable identifier. `endpoint` may contain path parameter templates in
    curly braces, for example `/users/{var1}`.

    `mitigation_action` is optional. When set, it creates the per operation schema validation setting and
    overrides the zone default for that operation.
  EOT

  type = map(object({
    host              = string
    method            = string
    endpoint          = string
    mitigation_action = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for o in values(var.operations) :
      contains(["GET", "POST", "HEAD", "OPTIONS", "PUT", "DELETE", "CONNECT", "PATCH", "TRACE"], o.method)
    ])
    error_message = "Each operation method must be one of GET, POST, HEAD, OPTIONS, PUT, DELETE, CONNECT, PATCH, TRACE."
  }

  validation {
    condition     = alltrue([for o in values(var.operations) : startswith(o.endpoint, "/")])
    error_message = "Each operation endpoint must be a path beginning with /."
  }

  validation {
    condition = alltrue([
      for o in values(var.operations) :
      o.mitigation_action == null || contains(["none", "log", "block"], coalesce(o.mitigation_action, "none"))
    ])
    error_message = "Each operation mitigation_action must be one of none, log, block."
  }
}

variable "schemas" {
  description = <<-EOT
    OpenAPI schemas uploaded through the original API Shield schema endpoint (`cloudflare_api_shield_schema`),
    keyed by a stable identifier. `file` is the raw schema bytes, usually `file("openapi.json")`.

    New configurations should prefer `validation_schemas`, which uses the Schema Validation 2.0 endpoint.
  EOT

  type = map(object({
    file               = string
    name               = optional(string)
    kind               = optional(string, "openapi_v3")
    validation_enabled = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.schemas) : s.kind == "openapi_v3"])
    error_message = "Each schema kind must be openapi_v3, the only value the provider accepts."
  }
}

variable "validation_schemas" {
  description = "OpenAPI schemas managed through Schema Validation 2.0 (`cloudflare_schema_validation_schemas`), keyed by a stable identifier. `source` is the raw schema as JSON or YAML."

  type = map(object({
    name               = string
    source             = string
    kind               = optional(string, "openapi_v3")
    validation_enabled = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.validation_schemas) : s.kind == "openapi_v3"])
    error_message = "Each validation schema kind must be openapi_v3, the only value the provider accepts."
  }
}

variable "schema_validation_settings" {
  description = <<-EOT
    Zone level Schema Validation 2.0 settings. Leave null to not manage them.

    `default_mitigation_action` applies to every operation without its own setting. `override_mitigation_action`
    accepts only `none`, which switches schema validation off for the whole zone without losing the per
    operation configuration; set it to null to clear the override.
  EOT

  type = object({
    default_mitigation_action  = string
    override_mitigation_action = optional(string)
  })
  default = null

  validation {
    condition     = var.schema_validation_settings == null || contains(["none", "log", "block"], try(var.schema_validation_settings.default_mitigation_action, ""))
    error_message = "schema_validation_settings.default_mitigation_action must be one of none, log, block."
  }

  validation {
    condition = (
      var.schema_validation_settings == null ||
      try(var.schema_validation_settings.override_mitigation_action, null) == null ||
      try(var.schema_validation_settings.override_mitigation_action, "") == "none"
    )
    error_message = "schema_validation_settings.override_mitigation_action accepts only the value none, or null to clear it."
  }
}

variable "use_legacy_operation_schema_validation" {
  description = <<-EOT
    Which resource backs the per operation mitigation action.

    `false` (the default) uses `cloudflare_schema_validation_operation_settings`. `true` uses
    `cloudflare_api_shield_operation_schema_validation_settings`, which the provider marks deprecated in favour
    of the former. Set it to true only while migrating existing state, then flip it and move the addresses.
  EOT

  type    = bool
  default = false
}
