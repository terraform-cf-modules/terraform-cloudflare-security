locals {
  enabled = var.enabled

  # Cloudflare evaluates rules in list order. Sort by the explicit priority first, then by key, so the
  # generated list is stable no matter how the map is written or how Terraform iterates it.
  rule_priorities = distinct(sort([for r in values(var.rules) : format("%012d", r.priority)]))

  rule_keys = flatten([
    for p in local.rule_priorities : [
      for k in sort(keys(var.rules)) : k
      if format("%012d", var.rules[k].priority) == p
    ]
  ])

  # action_parameters is normalised once per rule. The convenience shapes (plain string lists for the
  # log_custom_field members, a plain string list for compression algorithms) are expanded into the
  # object shapes the provider expects.
  action_parameters = {
    for k, r in var.rules : k => one([
      for ap in(r.action_parameters == null ? [] : [r.action_parameters]) : {
        id           = ap.id
        overrides    = ap.overrides
        matched_data = ap.matched_data

        ruleset  = ap.ruleset
        rulesets = ap.rulesets
        phases   = ap.phases
        products = ap.products
        rules    = ap.rules

        response = ap.response

        asset_name   = ap.asset_name
        content      = ap.content
        content_type = ap.content_type
        status_code  = ap.status_code

        from_value = ap.from_value
        from_list  = ap.from_list

        uri     = ap.uri
        headers = ap.headers

        increment = ap.increment

        algorithms = ap.algorithms == null ? null : [for a in ap.algorithms : { name = a }]

        automatic_https_rewrites = ap.automatic_https_rewrites
        autominify               = ap.autominify
        bic                      = ap.bic
        disable_apps             = ap.disable_apps
        disable_rum              = ap.disable_rum
        disable_zaraz            = ap.disable_zaraz
        email_obfuscation        = ap.email_obfuscation
        fonts                    = ap.fonts
        hotlink_protection       = ap.hotlink_protection
        mirage                   = ap.mirage
        opportunistic_encryption = ap.opportunistic_encryption
        polish                   = ap.polish
        rocket_loader            = ap.rocket_loader
        security_level           = ap.security_level
        server_side_excludes     = ap.server_side_excludes
        ssl                      = ap.ssl
        sxg                      = ap.sxg

        request_body_buffering  = ap.request_body_buffering
        response_body_buffering = ap.response_body_buffering

        cookie_fields              = ap.cookie_fields == null ? null : [for n in ap.cookie_fields : { name = n }]
        request_fields             = ap.request_fields == null ? null : [for n in ap.request_fields : { name = n }]
        transformed_request_fields = ap.transformed_request_fields == null ? null : [for n in ap.transformed_request_fields : { name = n }]
        response_fields            = ap.response_fields
        raw_response_fields        = ap.raw_response_fields
      }
    ])
  }

  rules = [
    for k in local.rule_keys : {
      action                   = var.rules[k].action
      expression               = var.rules[k].expression
      description              = var.rules[k].description
      enabled                  = var.rules[k].enabled
      ref                      = var.rules[k].ref
      logging                  = var.rules[k].logging
      ratelimit                = var.rules[k].ratelimit
      exposed_credential_check = var.rules[k].exposed_credential_check
      action_parameters        = local.action_parameters[k]
    }
  ]
}
