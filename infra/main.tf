resource "random_string" "suffix" {
  length  = 4
  lower   = true
  numeric = false
  special = false
  upper   = false
}

locals {
  suffix              = random_string.suffix.result
  resource_group_name = "${var.name_prefix}-${local.suffix}-rg"
  fleet_name          = "${var.name_prefix}-${local.suffix}"

  common_tags = merge(
    {
      demo       = "azure-kubernetes-fleet"
      managed_by = "terraform"
      project    = "fleet-manager-demo"
    },
    var.tags,
  )

  member_clusters = {
    staging = {
      environment = "staging"
      group       = "staging"
      short_name  = "stg"
    }
    canary = {
      environment = "canary"
      group       = "canary"
      short_name  = "canary"
    }
    production = {
      environment = "production"
      group       = "production"
      short_name  = "prod"
    }
  }
}

resource "azurerm_resource_group" "demo" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
