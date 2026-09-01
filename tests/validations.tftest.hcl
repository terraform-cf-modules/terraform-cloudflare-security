# Input validation. Plan only, no credentials.
#
# Every validation block in the root module and in the submodules gets at least one expect_failures case here.
# Submodule validations are reached with a `module` block inside the run.

mock_provider "cloudflare" {
  override_during = plan
}

variables {
  zone_id = "00000000000000000000000000000000"
}

# -----------------------------------------------------------------------------
# Scope anchors
# -----------------------------------------------------------------------------

run "rejects_malformed_account_id" {
  command = plan

  variables {
    account_id = "not-a-valid-account-id"
  }

  expect_failures = [var.account_id]
}

run "rejects_malformed_zone_id" {
  command = plan

  variables {
    zone_id = "TOO-SHORT"
  }

  expect_failures = [var.zone_id]
}

run "requires_a_zone_id_while_enabled" {
  command = plan

  variables {
    enabled = true
    zone_id = null
  }

  expect_failures = [var.zone_id]
}

run "allows_a_null_zone_id_while_disabled" {
  command = plan

  variables {
    enabled = false
    zone_id = null
  }

  assert {
    condition     = output.enabled == false
    error_message = "A disabled module must not require a zone ID."
  }
}

run "rejects_empty_name_prefix" {
  command = plan

  variables {
    name_prefix = "   "
  }

  expect_failures = [var.name_prefix]
}

# -----------------------------------------------------------------------------
# Managed rulesets
# -----------------------------------------------------------------------------

run "rejects_malformed_managed_ruleset_id" {
  command = plan

  variables {
    managed_rulesets = {
      bad = { id = "not-a-ruleset-id" }
    }
  }

  expect_failures = [var.managed_rulesets]
}

run "rejects_unknown_managed_ruleset_override_action" {
  command = plan

  variables {
    managed_rulesets = {
      cloudflare_managed = {
        id = "efb7b8c949ac4650a09736fc376e9aee"
        overrides = {
          action = "obliterate"
        }
      }
    }
  }

  expect_failures = [var.managed_rulesets]
}

# -----------------------------------------------------------------------------
# Custom rules
# -----------------------------------------------------------------------------

run "rejects_unknown_custom_rule_action" {
  command = plan

  variables {
    custom_rules = {
      bad = {
        expression = "true"
        action     = "set_cache_settings"
      }
    }
  }

  expect_failures = [var.custom_rules]
}

run "rejects_empty_custom_rule_expression" {
  command = plan

  variables {
    custom_rules = {
      bad = {
        expression = "  "
        action     = "block"
      }
    }
  }

  expect_failures = [var.custom_rules]
}

run "rejects_skip_rule_that_says_nothing_to_skip" {
  command = plan

  variables {
    custom_rules = {
      bad = {
        expression = "(ip.src in $office)"
        action     = "skip"
      }
    }
  }

  expect_failures = [var.custom_rules]
}

# -----------------------------------------------------------------------------
# Rate limit rules
# -----------------------------------------------------------------------------

run "rejects_unknown_rate_limit_action" {
  command = plan

  variables {
    rate_limit_rules = {
      bad = {
        expression          = "true"
        period              = 60
        requests_per_period = 10
        action              = "rewrite"
      }
    }
  }

  expect_failures = [var.rate_limit_rules]
}

run "rejects_unsupported_rate_limit_period" {
  command = plan

  variables {
    rate_limit_rules = {
      bad = {
        expression          = "true"
        period              = 45
        requests_per_period = 10
      }
    }
  }

  expect_failures = [var.rate_limit_rules]
}

run "rejects_rate_limit_with_neither_threshold" {
  command = plan

  variables {
    rate_limit_rules = {
      bad = {
        expression = "true"
        period     = 60
      }
    }
  }

  expect_failures = [var.rate_limit_rules]
}

run "rejects_rate_limit_with_both_thresholds" {
  command = plan

  variables {
    rate_limit_rules = {
      bad = {
        expression          = "true"
        period              = 60
        requests_per_period = 10
        score_per_period    = 100
      }
    }
  }

  expect_failures = [var.rate_limit_rules]
}

run "rejects_rate_limit_without_characteristics" {
  command = plan

  variables {
    rate_limit_rules = {
      bad = {
        expression          = "true"
        period              = 60
        requests_per_period = 10
        characteristics     = []
      }
    }
  }

  expect_failures = [var.rate_limit_rules]
}

# -----------------------------------------------------------------------------
# modules/ruleset
# -----------------------------------------------------------------------------

run "ruleset_rejects_unknown_kind" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = "test"
    kind    = "entrypoint"
    phase   = "http_request_firewall_custom"
  }

  expect_failures = [var.kind]
}

run "ruleset_rejects_unknown_phase" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = "test"
    kind    = "zone"
    phase   = "http_request_firewall"
  }

  expect_failures = [var.phase]
}

run "ruleset_rejects_empty_name" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = " "
    kind    = "zone"
    phase   = "http_request_firewall_custom"
  }

  expect_failures = [var.name]
}

run "ruleset_rejects_execute_without_a_ruleset_id" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = "test"
    kind    = "zone"
    phase   = "http_request_firewall_managed"
    rules = {
      bad = {
        expression = "true"
        action     = "execute"
      }
    }
  }

  expect_failures = [var.rules]
}

run "ruleset_rejects_unknown_header_operation" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = "test"
    kind    = "zone"
    phase   = "http_response_headers_transform"
    rules = {
      bad = {
        expression = "true"
        action     = "rewrite"
        action_parameters = {
          headers = {
            "X-Test" = { operation = "append", value = "1" }
          }
        }
      }
    }
  }

  expect_failures = [var.rules]
}

run "ruleset_rejects_unknown_skip_product" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    name    = "test"
    kind    = "zone"
    phase   = "http_request_firewall_custom"
    rules = {
      bad = {
        expression = "true"
        action     = "skip"
        action_parameters = {
          products = ["waf", "everything"]
        }
      }
    }
  }

  expect_failures = [var.rules]
}

run "ruleset_rejects_a_ruleset_with_neither_scope" {
  command = plan

  module {
    source = "./modules/ruleset"
  }

  variables {
    account_id = null
    zone_id    = null
    name       = "test"
    kind       = "zone"
    phase      = "http_request_firewall_custom"
    rules = {
      one = { expression = "true", action = "block" }
    }
  }

  expect_failures = [cloudflare_ruleset.this]
}

# -----------------------------------------------------------------------------
# modules/list
# -----------------------------------------------------------------------------

run "list_rejects_unknown_kind" {
  command = plan

  module {
    source = "./modules/list"
  }

  variables {
    account_id = "00000000000000000000000000000000"
    lists = {
      bad = { name = "bad", kind = "prefix" }
    }
  }

  expect_failures = [var.lists]
}

run "list_rejects_a_name_that_cannot_appear_in_an_expression" {
  command = plan

  module {
    source = "./modules/list"
  }

  variables {
    account_id = "00000000000000000000000000000000"
    lists = {
      bad = { name = "Office IPs", kind = "ip" }
    }
  }

  expect_failures = [var.lists]
}

run "list_rejects_an_item_with_two_value_types" {
  command = plan

  module {
    source = "./modules/list"
  }

  variables {
    account_id = "00000000000000000000000000000000"
    lists = {
      ips = { name = "ips", kind = "ip" }
    }
    items = {
      bad = { list_key = "ips", ip = "203.0.113.1", asn = 64496 }
    }
  }

  expect_failures = [var.items]
}

# -----------------------------------------------------------------------------
# modules/turnstile
# -----------------------------------------------------------------------------

run "turnstile_rejects_unknown_mode" {
  command = plan

  module {
    source = "./modules/turnstile"
  }

  variables {
    account_id = "00000000000000000000000000000000"
    widgets = {
      bad = { name = "bad", domains = ["example.com"], mode = "interactive" }
    }
  }

  expect_failures = [var.widgets]
}

run "turnstile_rejects_a_widget_without_domains" {
  command = plan

  module {
    source = "./modules/turnstile"
  }

  variables {
    account_id = "00000000000000000000000000000000"
    widgets = {
      bad = { name = "bad", domains = [] }
    }
  }

  expect_failures = [var.widgets]
}

# -----------------------------------------------------------------------------
# modules/bot-management
# -----------------------------------------------------------------------------

run "bot_management_rejects_unknown_sbfm_action" {
  command = plan

  module {
    source = "./modules/bot-management"
  }

  variables {
    zone_id               = "00000000000000000000000000000000"
    sbfm_likely_automated = "challenge"
  }

  expect_failures = [var.sbfm_likely_automated]
}

run "bot_management_rejects_unknown_ai_bots_protection" {
  command = plan

  module {
    source = "./modules/bot-management"
  }

  variables {
    zone_id            = "00000000000000000000000000000000"
    ai_bots_protection = "enabled"
  }

  expect_failures = [var.ai_bots_protection]
}

# -----------------------------------------------------------------------------
# modules/rate-limit
# -----------------------------------------------------------------------------

run "legacy_rate_limit_rejects_unknown_mode" {
  command = plan

  module {
    source = "./modules/rate-limit"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    rate_limits = {
      bad = {
        period    = 60
        threshold = 10
        action    = { mode = "block" }
        match     = { request = { url = "example.com/*" } }
      }
    }
  }

  expect_failures = [var.rate_limits]
}

run "legacy_rate_limit_rejects_unknown_header_operator" {
  command = plan

  module {
    source = "./modules/rate-limit"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    rate_limits = {
      bad = {
        period    = 60
        threshold = 10
        action    = { mode = "ban" }
        match = {
          headers = [{ name = "x-test", op = "contains", value = "1" }]
        }
      }
    }
  }

  expect_failures = [var.rate_limits]
}

# -----------------------------------------------------------------------------
# modules/firewall-legacy
# -----------------------------------------------------------------------------

run "legacy_firewall_rejects_unknown_access_rule_target" {
  command = plan

  module {
    source = "./modules/firewall-legacy"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    access_rules = {
      bad = {
        mode          = "block"
        configuration = { target = "subnet", value = "203.0.113.0/24" }
      }
    }
  }

  expect_failures = [var.access_rules]
}

run "legacy_firewall_rejects_unknown_user_agent_mode" {
  command = plan

  module {
    source = "./modules/firewall-legacy"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    user_agent_blocking_rules = {
      bad = { mode = "ban", value = "BadBot/1.0" }
    }
  }

  expect_failures = [var.user_agent_blocking_rules]
}

run "legacy_firewall_rejects_a_lockdown_without_urls" {
  command = plan

  module {
    source = "./modules/firewall-legacy"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    zone_lockdowns = {
      bad = {
        urls           = []
        configurations = [{ target = "ip", value = "203.0.113.1" }]
      }
    }
  }

  expect_failures = [var.zone_lockdowns]
}

# -----------------------------------------------------------------------------
# modules/api-shield
# -----------------------------------------------------------------------------

run "api_shield_rejects_unknown_characteristic_type" {
  command = plan

  module {
    source = "./modules/api-shield"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    auth_id_characteristics = [
      { name = "authorization", type = "query" },
    ]
  }

  expect_failures = [var.auth_id_characteristics]
}

run "api_shield_rejects_unknown_method" {
  command = plan

  module {
    source = "./modules/api-shield"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    operations = {
      bad = { host = "api.example.com", method = "LIST", endpoint = "/v1/users" }
    }
  }

  expect_failures = [var.operations]
}

run "api_shield_rejects_a_bad_override_mitigation_action" {
  command = plan

  module {
    source = "./modules/api-shield"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    schema_validation_settings = {
      default_mitigation_action  = "log"
      override_mitigation_action = "block"
    }
  }

  expect_failures = [var.schema_validation_settings]
}

# -----------------------------------------------------------------------------
# modules/page-shield
# -----------------------------------------------------------------------------

run "page_shield_rejects_unknown_policy_action" {
  command = plan

  module {
    source = "./modules/page-shield"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    policies = {
      bad = {
        description = "bad"
        expression  = "true"
        value       = "script-src 'self'"
        action      = "block"
      }
    }
  }

  expect_failures = [var.policies]
}

run "page_shield_rejects_an_empty_scan_expression" {
  command = plan

  module {
    source = "./modules/page-shield"
  }

  variables {
    zone_id = "00000000000000000000000000000000"
    content_scanning_expressions = {
      bad = "  "
    }
  }

  expect_failures = [var.content_scanning_expressions]
}
