# Applies against a real Cloudflare test account.
# Runs on a schedule and on manual dispatch only, never on pull requests,
# because fork pull requests cannot read organisation secrets.

variables {
  account_id = null # supplied by TF_VAR_account_id
  zone_id    = null # supplied by TF_VAR_zone_id
}

run "apply_and_destroy" {
  command = apply

  variables {
    name_prefix = "tf-integration"

    custom_rules = {
      block_probe = {
        priority    = 100
        description = "Integration test rule"
        expression  = "(http.request.uri.path eq \"/terraform-integration-test\")"
        action      = "block"
      }
    }

    rate_limit_rules = {
      probe = {
        priority            = 100
        description         = "Integration test rate limit"
        expression          = "(http.request.uri.path eq \"/terraform-integration-test\")"
        period              = 60
        requests_per_period = 100
        action              = "log"
      }
    }
  }

  assert {
    condition     = output.enabled == true
    error_message = "Module did not report enabled after apply."
  }

  assert {
    condition     = output.managed_ruleset_id != null
    error_message = "The managed WAF entry point ruleset was not created."
  }

  assert {
    condition     = output.custom_ruleset_id != null
    error_message = "The custom WAF entry point ruleset was not created."
  }

  assert {
    condition     = output.rate_limit_ruleset_id != null
    error_message = "The rate limiting entry point ruleset was not created."
  }

  assert {
    condition     = jsonencode(output.custom_rule_order) == jsonencode(["block_probe"])
    error_message = "Unexpected custom rule order after apply: ${jsonencode(output.custom_rule_order)}."
  }
}
