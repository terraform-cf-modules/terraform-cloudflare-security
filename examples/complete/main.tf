# Every optional feature of the Cloudflare Security module turned on.
#
# The root module covers the zone WAF baseline. The submodules below cover the rest of the security surface:
# lists that the WAF rules reference, Turnstile widgets, API Shield, Page Shield, and the deprecated legacy
# firewall resources kept for migration.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

# -----------------------------------------------------------------------------
# Lists referenced by the WAF rules below. Lists are account scoped.
# -----------------------------------------------------------------------------

module "lists" {
  source = "../../modules/list"

  account_id = var.account_id

  lists = {
    office_ips = {
      name        = "office_ips"
      kind        = "ip"
      description = "Corporate egress ranges"
      items = [
        { ip = "203.0.113.0/24", comment = "London office" },
        { ip = "198.51.100.7", comment = "Bastion" },
      ]
    }

    blocked_asns = {
      name        = "blocked_asns"
      kind        = "asn"
      description = "Networks with a history of scraping"
    }
  }

  items = {
    as64496 = { list_key = "blocked_asns", asn = 64496, comment = "Scraper" }
    as64497 = { list_key = "blocked_asns", asn = 64497, comment = "Scraper" }
  }
}

# -----------------------------------------------------------------------------
# The WAF baseline itself.
# -----------------------------------------------------------------------------

module "this" {
  source = "../../"

  enabled     = true
  account_id  = var.account_id
  zone_id     = var.zone_id
  name_prefix = "complete-example"

  # Managed rulesets, with category and rule level overrides.
  managed_rulesets_enabled = true
  managed_rulesets = {
    cloudflare_managed = {
      id          = "efb7b8c949ac4650a09736fc376e9aee"
      description = "Cloudflare Managed Ruleset"
      priority    = 10

      overrides = {
        enabled = true
        categories = [
          { category = "wordpress", action = "block", enabled = true },
          { category = "joomla", enabled = false },
        ]
      }
    }

    owasp_core = {
      id          = "4814384a9e5d4991b9815dcfc25d2f1f"
      description = "Cloudflare OWASP Core Ruleset"
      priority    = 20

      overrides = {
        enabled = true
        rules = [
          {
            id              = "6179ae15870a4bb7b2d480d4843b323c"
            action          = "log"
            enabled         = true
            score_threshold = 40
          },
        ]
      }
    }
  }

  # Zone specific rules. Priority controls evaluation order, not map order.
  custom_rules = {
    allow_office = {
      priority    = 10
      description = "Corporate egress skips the rest of the custom phase"
      expression  = "(ip.src in $office_ips)"
      action      = "skip"
      action_parameters = {
        ruleset = "current"
      }
      logging = { enabled = true }
    }

    block_scraper_asns = {
      priority    = 100
      description = "Known scraper networks"
      expression  = "(ip.geoip.asnum in $blocked_asns)"
      action      = "block"
    }

    challenge_login = {
      priority    = 200
      description = "Interactive challenge on the login form"
      expression  = "(http.request.uri.path eq \"/login\" and http.request.method eq \"POST\")"
      action      = "managed_challenge"
    }

    block_admin_from_outside = {
      priority    = 300
      description = "Admin surface is office only"
      expression  = "(starts_with(http.request.uri.path, \"/admin\") and not ip.src in $office_ips)"
      action      = "block"
      action_parameters = {
        response = {
          status_code  = 403
          content_type = "application/json"
          content      = "{\"error\":\"forbidden\"}"
        }
      }
    }

    log_leaked_credentials = {
      priority    = 400
      description = "Record sign-in attempts using known leaked credentials"
      expression  = "(http.request.uri.path eq \"/login\")"
      action      = "log"
      exposed_credential_check = {
        username_expression = "url_decode(http.request.body.form[\"username\"][0])"
        password_expression = "url_decode(http.request.body.form[\"password\"][0])"
      }
    }
  }

  # Rate limiting, as an http_ratelimit ruleset.
  rate_limit_rules = {
    login = {
      priority            = 10
      description         = "Twenty login attempts a minute per IP"
      expression          = "(http.request.uri.path eq \"/login\" and http.request.method eq \"POST\")"
      period              = 60
      requests_per_period = 20
      characteristics     = ["ip.src", "cf.colo.id"]
      mitigation_timeout  = 600
      action              = "block"

      response = {
        status_code  = 429
        content_type = "application/json"
        content      = "{\"error\":\"too many requests\"}"
      }
    }

    api = {
      priority            = 20
      description         = "API budget per client token"
      expression          = "(starts_with(http.request.uri.path, \"/api/\"))"
      period              = 60
      requests_per_period = 600
      characteristics     = ["ip.src", "cf.colo.id"]
      requests_to_origin  = true
      action              = "managed_challenge"
    }
  }

  # Bot management. Which fields are accepted depends on the zone plan.
  bot_management = {
    enable_js         = true
    auto_update_model = true

    sbfm_definitely_automated       = "block"
    sbfm_likely_automated           = "managed_challenge"
    sbfm_verified_bots              = "allow"
    sbfm_static_resource_protection = false

    ai_bots_protection = "block"
    crawler_protection = "disabled"
  }
}

# -----------------------------------------------------------------------------
# Response header hardening, which lives in a transform phase rather than a WAF
# phase, so it goes through modules/ruleset directly.
# -----------------------------------------------------------------------------

module "security_headers" {
  source = "../../modules/ruleset"

  zone_id = var.zone_id
  name    = "complete-example response headers"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules = {
    harden = {
      priority    = 10
      description = "Baseline security headers"
      expression  = "true"
      action      = "rewrite"
      action_parameters = {
        headers = {
          "Strict-Transport-Security" = { operation = "set", value = "max-age=31536000; includeSubDomains" }
          "X-Content-Type-Options"    = { operation = "set", value = "nosniff" }
          "X-Frame-Options"           = { operation = "set", value = "DENY" }
          "Referrer-Policy"           = { operation = "set", value = "strict-origin-when-cross-origin" }
          "Server"                    = { operation = "remove" }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Turnstile.
# -----------------------------------------------------------------------------

module "turnstile" {
  source = "../../modules/turnstile"

  account_id = var.account_id

  widgets = {
    signup = {
      name    = "complete-example signup"
      domains = ["example.com", "www.example.com"]
      mode    = "managed"
    }

    api = {
      name           = "complete-example API clients"
      domains        = ["api.example.com"]
      mode           = "invisible"
      bot_fight_mode = true
    }
  }
}

# -----------------------------------------------------------------------------
# API Shield.
# -----------------------------------------------------------------------------

module "api_shield" {
  source = "../../modules/api-shield"

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

    create_user = {
      host              = "api.example.com"
      method            = "POST"
      endpoint          = "/v1/users"
      mitigation_action = "block"
    }
  }

  validation_schemas = {
    public_api = {
      name               = "public-api"
      source             = jsonencode(local.openapi_schema)
      validation_enabled = true
    }
  }

  schema_validation_settings = {
    default_mitigation_action = "log"
  }
}

# -----------------------------------------------------------------------------
# Page Shield and content scanning.
# -----------------------------------------------------------------------------

module "page_shield" {
  source = "../../modules/page-shield"

  zone_id = var.zone_id

  policies = {
    checkout = {
      description = "Report on anything but first party and payment scripts during checkout"
      expression  = "starts_with(http.request.uri.path, \"/checkout\")"
      action      = "log"
      value       = "script-src 'self' https://js.example-payments.com"
      enabled     = true
    }
  }

  content_scanning = true

  content_scanning_expressions = {
    upload_field = "lookup_json_string(http.request.body.raw, \"file\")"
  }
}

# -----------------------------------------------------------------------------
# Legacy firewall. Deprecated by Cloudflare; present so an existing estate can
# be adopted and migrated. Do not start here.
# -----------------------------------------------------------------------------

module "legacy_firewall" {
  source = "../../modules/firewall-legacy"

  zone_id = var.zone_id

  firewall_rules = {
    block_wp_probes = {
      filter = {
        expression  = "(http.request.uri.path contains \"/wp-admin\")"
        description = "WordPress probing on a site that does not run WordPress"
      }
      action = { mode = "block" }
    }
  }

  access_rules = {
    block_country = {
      mode          = "block"
      notes         = "Sanctioned jurisdiction"
      configuration = { target = "country", value = "T1" }
    }
  }

  user_agent_blocking_rules = {
    bad_scraper = {
      mode        = "block"
      value       = "BadScraper/1.0"
      description = "Scraper that ignores robots.txt"
    }
  }

  zone_lockdowns = {
    admin = {
      description    = "Admin surface restricted to the office"
      urls           = ["example.com/admin*"]
      configurations = [{ target = "ip_range", value = "203.0.113.0/24" }]
    }
  }
}

# -----------------------------------------------------------------------------
# Deprecated per zone rate limits, alongside the ruleset based ones above.
# -----------------------------------------------------------------------------

module "legacy_rate_limit" {
  source = "../../modules/rate-limit"

  zone_id = var.zone_id

  rate_limits = {
    password_reset = {
      period    = 60
      threshold = 5

      action = {
        mode    = "simulate"
        timeout = 600
      }

      match = {
        request = {
          url     = "example.com/password-reset"
          methods = ["POST"]
          schemes = ["HTTPS"]
        }
      }
    }
  }
}
