# One ruleset per phase, built directly from modules/ruleset.
#
# The root module wires up the three WAF phases for you. This example is for the case the root module does not
# cover: a zone that needs transform, redirect, config or logging phases as well, each of which is a separate
# entry point ruleset with a different set of legal action_parameters.
#
# It also shows the two things that are easy to get wrong with cloudflare_ruleset:
#
#   1. Rule order comes from `priority`, not from where the rule sits in the map. Round numbers with gaps leave
#      room to insert a rule later without renumbering.
#   2. A zone holds exactly one entry point ruleset per phase. Two module instances with the same zone and
#      phase will fight over the same object on every apply.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

# -----------------------------------------------------------------------------
# http_request_firewall_managed: run Cloudflare's managed rulesets.
# -----------------------------------------------------------------------------

module "managed" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example managed WAF"
  kind    = "zone"
  phase   = "http_request_firewall_managed"

  rules = {
    cloudflare_managed = {
      priority   = 10
      expression = "true"
      action     = "execute"
      action_parameters = {
        id = "efb7b8c949ac4650a09736fc376e9aee"
        overrides = {
          enabled = true
          categories = [
            { category = "wordpress", action = "block", enabled = true },
          ]
        }
      }
    }

    owasp = {
      priority   = 20
      expression = "true"
      action     = "execute"
      action_parameters = {
        id = "4814384a9e5d4991b9815dcfc25d2f1f"
        overrides = {
          enabled = true
          rules = [
            { id = "6179ae15870a4bb7b2d480d4843b323c", action = "log", score_threshold = 40 },
          ]
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_request_firewall_custom: zone specific rules.
# -----------------------------------------------------------------------------

module "custom" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example custom WAF"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = {
    # Written last in the map, evaluated first, because priority wins.
    skip_healthcheck = {
      priority   = 10
      expression = "(http.request.uri.path eq \"/healthz\")"
      action     = "skip"
      action_parameters = {
        phases = ["http_request_firewall_managed", "http_ratelimit"]
      }
    }

    block_probes = {
      priority   = 100
      expression = "(http.request.uri.path contains \"/.env\" or http.request.uri.path contains \"/.git/\")"
      action     = "block"
      logging    = { enabled = true }
    }

    score_suspicious = {
      priority   = 200
      expression = "(cf.threat_score gt 20)"
      action     = "score"
      action_parameters = {
        increment = 10
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_ratelimit: the current rate limiting product.
# -----------------------------------------------------------------------------

module "rate_limit" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example rate limiting"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = {
    api_per_token = {
      priority   = 10
      expression = "(starts_with(http.request.uri.path, \"/api/\"))"
      action     = "block"

      ratelimit = {
        # Counting on a header rather than the source IP gives a per client budget behind shared NAT.
        characteristics     = ["cf.colo.id", "http.request.headers[\"x-api-key\"]"]
        period              = 60
        requests_per_period = 600
        mitigation_timeout  = 60
        requests_to_origin  = true
      }

      action_parameters = {
        response = {
          status_code  = 429
          content_type = "application/json"
          content      = "{\"error\":\"rate limited\"}"
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_request_transform: rewrite the request URI before it is served.
# -----------------------------------------------------------------------------

module "request_transform" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example request transform"
  kind    = "zone"
  phase   = "http_request_transform"

  rules = {
    strip_legacy_prefix = {
      priority   = 10
      expression = "(starts_with(http.request.uri.path, \"/old/\"))"
      action     = "rewrite"
      action_parameters = {
        uri = {
          path = {
            expression = "regex_replace(http.request.uri.path, \"^/old/\", \"/\")"
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_response_headers_transform: security headers on the way out.
# -----------------------------------------------------------------------------

module "response_headers" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example response headers"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules = {
    harden = {
      priority   = 10
      expression = "true"
      action     = "rewrite"
      action_parameters = {
        headers = {
          "Strict-Transport-Security" = { operation = "set", value = "max-age=31536000; includeSubDomains; preload" }
          "X-Content-Type-Options"    = { operation = "set", value = "nosniff" }
          "Referrer-Policy"           = { operation = "set", value = "strict-origin-when-cross-origin" }
          "Permissions-Policy"        = { operation = "set", value = "geolocation=(), microphone=(), camera=()" }
          "Server"                    = { operation = "remove" }
          "X-Powered-By"              = { operation = "remove" }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_request_dynamic_redirect: redirects driven by an expression or a list.
# -----------------------------------------------------------------------------

module "dynamic_redirect" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example dynamic redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = {
    canonical_host = {
      priority   = 10
      expression = "(http.host eq \"www.example.com\")"
      action     = "redirect"
      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = true
          target_url = {
            expression = "concat(\"https://example.com\", http.request.uri.path)"
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_config_settings: per request setting overrides.
# -----------------------------------------------------------------------------

module "config_settings" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example config settings"
  kind    = "zone"
  phase   = "http_config_settings"

  rules = {
    tighten_admin = {
      priority   = 10
      expression = "(starts_with(http.request.uri.path, \"/admin\"))"
      action     = "set_config"
      action_parameters = {
        security_level    = "high"
        bic               = true
        email_obfuscation = false
      }
    }
  }
}

# -----------------------------------------------------------------------------
# http_log_custom_fields: extra fields in the zone's HTTP logs.
# -----------------------------------------------------------------------------

module "log_custom_fields" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "phases example log custom fields"
  kind    = "zone"
  phase   = "http_log_custom_fields"

  rules = {
    request_context = {
      priority   = 10
      expression = "true"
      action     = "log_custom_field"
      action_parameters = {
        request_fields  = ["content-type", "x-request-id"]
        cookie_fields   = ["session"]
        response_fields = [{ name = "server", preserve_duplicates = false }]
      }
    }
  }
}
