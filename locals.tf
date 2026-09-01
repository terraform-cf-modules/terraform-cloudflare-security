locals {
  # Single switch consulted by every resource in this module.
  enabled = var.enabled

  # Each phase gets its own entry point ruleset, and each is only created when there is something to put in it.
  # An empty entry point ruleset is not a no-op: it takes ownership of the phase and clears whatever was there.
  create_managed   = local.enabled && var.managed_rulesets_enabled
  create_custom    = local.enabled && length(var.custom_rules) > 0
  create_ratelimit = local.enabled && length(var.rate_limit_rules) > 0
  create_bots      = local.enabled && var.bot_management != null

  # Managed rulesets are deployed by an "execute" rule per ruleset ID.
  managed_rules = {
    for k, r in var.managed_rulesets : k => {
      expression  = r.expression
      action      = "execute"
      description = coalesce(r.description, "Execute managed ruleset ${r.id}")
      enabled     = r.enabled
      priority    = r.priority

      action_parameters = {
        id           = r.id
        overrides    = r.overrides
        matched_data = r.matched_data_public_key == null ? null : { public_key = r.matched_data_public_key }
      }
    }
  }

  # Rate limit rules are flattened in the input for readability and reassembled into the ruleset shape here.
  ratelimit_rules = {
    for k, r in var.rate_limit_rules : k => {
      expression  = r.expression
      action      = r.action
      description = r.description
      enabled     = r.enabled
      ref         = r.ref
      priority    = r.priority

      ratelimit = {
        characteristics            = r.characteristics
        period                     = r.period
        requests_per_period        = r.requests_per_period
        score_per_period           = r.score_per_period
        counting_expression        = r.counting_expression
        mitigation_timeout         = r.mitigation_timeout
        requests_to_origin         = r.requests_to_origin
        score_response_header_name = r.score_response_header_name
      }

      action_parameters = r.response == null ? null : { response = r.response }
    }
  }
}
