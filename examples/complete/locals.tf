locals {
  # Inlined so the example validates without any file next to it. In a real configuration this is
  # file("${path.module}/openapi.json") or the output of whatever generates the spec.
  openapi_schema = {
    openapi = "3.0.0"
    info = {
      title   = "Example API"
      version = "1.0.0"
    }
    servers = [{ url = "https://api.example.com" }]
    paths = {
      "/v1/users" = {
        get  = { responses = { "200" = { description = "OK" } } }
        post = { responses = { "201" = { description = "Created" } } }
      }
      "/v1/users/{id}" = {
        get = {
          parameters = [{
            name     = "id"
            in       = "path"
            required = true
            schema   = { type = "string" }
          }]
          responses = { "200" = { description = "OK" } }
        }
      }
    }
  }
}
