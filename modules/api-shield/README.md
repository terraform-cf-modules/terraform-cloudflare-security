# api-shield

Manages API Shield on a zone: client identification, tracked operations, uploaded OpenAPI schemas, and schema
validation settings.

| Resource | Purpose |
|----------|---------|
| `cloudflare_api_shield` | Auth ID characteristics, the fields that identify an API client |
| `cloudflare_api_shield_operation` | One tracked endpoint (host, method, path) |
| `cloudflare_schema_validation_operation_settings` | Per operation mitigation action |
| `cloudflare_api_shield_operation_schema_validation_settings` | The deprecated form of the same thing |
| `cloudflare_api_shield_schema` | Schema upload, original endpoint (deprecated) |
| `cloudflare_schema_validation_schemas` | Schema upload, Schema Validation 2.0 |
| `cloudflare_schema_validation_settings` | Zone level default and override mitigation actions |

## Two generations of schema validation

The provider carries both, and marks the older pair deprecated:

- `cloudflare_api_shield_schema` -> use `cloudflare_schema_validation_schemas`
- `cloudflare_api_shield_operation_schema_validation_settings` -> use
  `cloudflare_schema_validation_operation_settings`

This module defaults to the current resources. `schemas` still exists for adopting existing state, and
`use_legacy_operation_schema_validation = true` switches the per operation settings back to the deprecated
resource. Both produce a provider deprecation warning on plan, which is the intended signal to migrate.

Do not manage the same schema through both paths.

## Usage

```hcl
module "api_shield" {
  source  = "terraform-cf-modules/security/cloudflare//modules/api-shield"
  version = "~> 0.1"

  zone_id = var.zone_id

  auth_id_characteristics = [
    { name = "authorization", type = "header" },
    { name = "session", type = "cookie" },
  ]

  operations = {
    list_users = {
      host              = "api.example.com"
      method            = "GET"
      endpoint          = "/v1/users"
      mitigation_action = "log"
    }
    get_user = {
      host              = "api.example.com"
      method            = "GET"
      endpoint          = "/v1/users/{var1}"
      mitigation_action = "block"
    }
  }

  validation_schemas = {
    public_api = {
      name               = "public-api"
      source             = file("${path.module}/openapi.json")
      validation_enabled = true
    }
  }

  schema_validation_settings = {
    default_mitigation_action = "log"
  }
}
```

## Notes

- `endpoint` uses Cloudflare's path parameter templates: `{var1}`, `{var2}` and so on, replaced left to right.
  The path is normalised on insertion, so what comes back may not match what was sent character for character.
- `auth_id_characteristics` is a list, not a map, because the API replaces the whole set on every write and the
  ordering is meaningful to Cloudflare's discovery. Leaving it empty creates no `cloudflare_api_shield`
  resource at all.
- `schema_validation_settings.override_mitigation_action` accepts only `none`. It switches validation off zone
  wide without discarding the per operation configuration. Set it to null to clear the override.
- Almost everything else on `cloudflare_api_shield_operation` (thresholds, confidence intervals, learned
  schemas) is computed by Cloudflare and read only. It surfaces through the `operations` output.
- API Shield is an Enterprise add-on. On a plan without it the API rejects these calls.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_api_shield.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/api_shield) | resource |
| [cloudflare_api_shield_operation.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/api_shield_operation) | resource |
| [cloudflare_api_shield_operation_schema_validation_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/api_shield_operation_schema_validation_settings) | resource |
| [cloudflare_api_shield_schema.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/api_shield_schema) | resource |
| [cloudflare_schema_validation_operation_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/schema_validation_operation_settings) | resource |
| [cloudflare_schema_validation_schemas.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/schema_validation_schemas) | resource |
| [cloudflare_schema_validation_settings.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/schema_validation_settings) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID that API Shield is configured on. | `string` | n/a | yes |
| <a name="input_auth_id_characteristics"></a> [auth\_id\_characteristics](#input\_auth\_id\_characteristics) | Fields that identify an API client, used for per client rate thresholds and for endpoint discovery. Setting<br/>this creates the `cloudflare_api_shield` configuration for the zone; leaving it empty creates nothing. | <pre>list(object({<br/>    name = string<br/>    type = string<br/>  }))</pre> | `[]` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_operations"></a> [operations](#input\_operations) | API endpoints to track, keyed by a stable identifier. `endpoint` may contain path parameter templates in<br/>curly braces, for example `/users/{var1}`.<br/><br/>`mitigation_action` is optional. When set, it creates the per operation schema validation setting and<br/>overrides the zone default for that operation. | <pre>map(object({<br/>    host              = string<br/>    method            = string<br/>    endpoint          = string<br/>    mitigation_action = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_schema_validation_settings"></a> [schema\_validation\_settings](#input\_schema\_validation\_settings) | Zone level Schema Validation 2.0 settings. Leave null to not manage them.<br/><br/>`default_mitigation_action` applies to every operation without its own setting. `override_mitigation_action`<br/>accepts only `none`, which switches schema validation off for the whole zone without losing the per<br/>operation configuration; set it to null to clear the override. | <pre>object({<br/>    default_mitigation_action  = string<br/>    override_mitigation_action = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_schemas"></a> [schemas](#input\_schemas) | OpenAPI schemas uploaded through the original API Shield schema endpoint (`cloudflare_api_shield_schema`),<br/>keyed by a stable identifier. `file` is the raw schema bytes, usually `file("openapi.json")`.<br/><br/>New configurations should prefer `validation_schemas`, which uses the Schema Validation 2.0 endpoint. | <pre>map(object({<br/>    file               = string<br/>    name               = optional(string)<br/>    kind               = optional(string, "openapi_v3")<br/>    validation_enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_use_legacy_operation_schema_validation"></a> [use\_legacy\_operation\_schema\_validation](#input\_use\_legacy\_operation\_schema\_validation) | Which resource backs the per operation mitigation action.<br/><br/>`false` (the default) uses `cloudflare_schema_validation_operation_settings`. `true` uses<br/>`cloudflare_api_shield_operation_schema_validation_settings`, which the provider marks deprecated in favour<br/>of the former. Set it to true only while migrating existing state, then flip it and move the addresses. | `bool` | `false` | no |
| <a name="input_validation_schemas"></a> [validation\_schemas](#input\_validation\_schemas) | OpenAPI schemas managed through Schema Validation 2.0 (`cloudflare_schema_validation_schemas`), keyed by a stable identifier. `source` is the raw schema as JSON or YAML. | <pre>map(object({<br/>    name               = string<br/>    source             = string<br/>    kind               = optional(string, "openapi_v3")<br/>    validation_enabled = optional(bool, true)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_shield"></a> [api\_shield](#output\_api\_shield) | The full cloudflare\_api\_shield object, or null when it was not created. |
| <a name="output_api_shield_id"></a> [api\_shield\_id](#output\_api\_shield\_id) | Identifier of the API Shield configuration, or null when no auth ID characteristics were given. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_operation_ids"></a> [operation\_ids](#output\_operation\_ids) | Map of operation key to the operation UUID, which is what rate limiting and schema settings reference. |
| <a name="output_operation_validation_settings"></a> [operation\_validation\_settings](#output\_operation\_validation\_settings) | Map of operation key to the full per operation schema validation settings object, from whichever of the two resources is in use. |
| <a name="output_operations"></a> [operations](#output\_operations) | Map of operation key to the full cloudflare\_api\_shield\_operation object. |
| <a name="output_schema_ids"></a> [schema\_ids](#output\_schema\_ids) | Map of schema key to the uploaded schema UUID. |
| <a name="output_schema_validation_settings"></a> [schema\_validation\_settings](#output\_schema\_validation\_settings) | The zone level Schema Validation 2.0 settings object, or null when not managed. |
| <a name="output_schemas"></a> [schemas](#output\_schemas) | Map of schema key to the full cloudflare\_api\_shield\_schema object. |
| <a name="output_validation_schema_ids"></a> [validation\_schema\_ids](#output\_validation\_schema\_ids) | Map of Schema Validation 2.0 schema key to its UUID. |
| <a name="output_validation_schemas"></a> [validation\_schemas](#output\_validation\_schemas) | Map of Schema Validation 2.0 schema key to the full cloudflare\_schema\_validation\_schemas object. |
<!-- END_TF_DOCS -->
