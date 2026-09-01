# Plan only. Runs on every pull request, including forks, with no credentials.

mock_provider "cloudflare" {
  override_during = plan
}

variables {
  account_id = "00000000000000000000000000000000"
  zone_id    = "00000000000000000000000000000000"
}

run "creates_nothing_when_disabled" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = output.enabled == false
    error_message = "Module reported enabled while var.enabled was false."
  }

  assert {
    condition     = output.managed_ruleset_id == null
    error_message = "A disabled module still produced a managed ruleset ID."
  }

  assert {
    condition     = output.bot_management_id == null
    error_message = "A disabled module still produced a bot management ID."
  }
}

run "enabled_by_default" {
  command = plan

  assert {
    condition     = output.enabled == true
    error_message = "Module should be enabled by default."
  }
}

run "deploys_the_managed_baseline_by_default" {
  command = plan

  # The baseline is the point of the root module: with nothing but a zone ID it deploys the Cloudflare Managed
  # Ruleset and the OWASP Core Ruleset, in that order.
  assert {
    condition     = jsonencode(output.managed_ruleset_rule_order) == jsonencode(["cloudflare_managed", "owasp_core"])
    error_message = "Default managed ruleset order was ${jsonencode(output.managed_ruleset_rule_order)}."
  }
}

run "creates_no_custom_or_ratelimit_phase_without_rules" {
  command = plan

  assert {
    condition     = output.custom_ruleset_id == null
    error_message = "A custom firewall ruleset was created with no custom rules. An empty entry point ruleset takes ownership of the phase and clears it."
  }

  assert {
    condition     = output.rate_limit_ruleset_id == null
    error_message = "A rate limiting ruleset was created with no rate limit rules."
  }
}

run "custom_rules_are_ordered_by_priority_not_map_order" {
  command = plan

  variables {
    custom_rules = {
      zulu = {
        priority   = 10
        expression = "(ip.src in $office)"
        action     = "skip"
        action_parameters = {
          ruleset = "current"
        }
      }
      alpha = {
        priority   = 30
        expression = "(http.request.uri.path eq \"/login\")"
        action     = "managed_challenge"
      }
      mike = {
        priority   = 20
        expression = "(ip.src.country eq \"T1\")"
        action     = "block"
      }
    }
  }

  assert {
    condition     = jsonencode(output.custom_rule_order) == jsonencode(["zulu", "mike", "alpha"])
    error_message = "Custom rules were ordered ${jsonencode(output.custom_rule_order)}, expected zulu, mike, alpha."
  }

  assert {
    condition     = output.custom_ruleset_id != null || output.enabled
    error_message = "Custom rules were supplied but no custom ruleset was planned."
  }
}

run "equal_priorities_fall_back_to_key_order" {
  command = plan

  variables {
    custom_rules = {
      charlie = { expression = "(http.host eq \"c.example.com\")", action = "block" }
      alpha   = { expression = "(http.host eq \"a.example.com\")", action = "block" }
      bravo   = { expression = "(http.host eq \"b.example.com\")", action = "block" }
    }
  }

  assert {
    condition     = jsonencode(output.custom_rule_order) == jsonencode(["alpha", "bravo", "charlie"])
    error_message = "Rules sharing a priority must fall back to alphabetical key order, got ${jsonencode(output.custom_rule_order)}."
  }
}

run "rate_limit_rules_build_a_ratelimit_phase" {
  command = plan

  variables {
    rate_limit_rules = {
      login = {
        priority            = 10
        expression          = "(http.request.uri.path eq \"/login\")"
        period              = 60
        requests_per_period = 20
      }
      api = {
        priority            = 20
        expression          = "(starts_with(http.request.uri.path, \"/api/\"))"
        period              = 600
        requests_per_period = 5000
        action              = "managed_challenge"
      }
    }
  }

  assert {
    condition     = jsonencode(output.rate_limit_rule_order) == jsonencode(["login", "api"])
    error_message = "Rate limit rules were ordered ${jsonencode(output.rate_limit_rule_order)}."
  }
}

run "managed_rulesets_can_be_turned_off" {
  command = plan

  variables {
    managed_rulesets_enabled = false
  }

  assert {
    condition     = output.managed_ruleset_id == null
    error_message = "managed_rulesets_enabled = false still produced a managed ruleset."
  }
}

run "bot_management_is_off_unless_configured" {
  command = plan

  assert {
    condition     = output.bot_management == null
    error_message = "Bot management was managed without being configured. Leaving it null must leave the zone setting alone."
  }
}

run "bot_management_is_managed_when_configured" {
  command = plan

  variables {
    bot_management = {
      enable_js                 = true
      sbfm_definitely_automated = "block"
      ai_bots_protection        = "block"
    }
  }

  assert {
    condition     = try(output.bot_management.enable_js, null) == true
    error_message = "Bot management was configured but the planned resource did not carry the requested settings."
  }

  assert {
    condition     = try(output.bot_management.sbfm_definitely_automated, null) == "block"
    error_message = "Bot management settings were not passed through to the submodule."
  }
}
