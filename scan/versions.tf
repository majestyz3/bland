terraform {
  required_version = ">= 1.7.0"

  required_providers {
    bland = {
      source  = "majestyz3/bland"
      version = "0.1.0"
    }
  }
}

# API key comes from the BLAND_API_KEY environment variable.
# BLAND_BASE_URL can point the provider at a mock API for tests.
provider "bland" {}
