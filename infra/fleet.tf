resource "azapi_resource" "fleet" {
  type      = "Microsoft.ContainerService/fleets@2025-03-01"
  name      = local.fleet_name
  location  = azurerm_resource_group.demo.location
  parent_id = azurerm_resource_group.demo.id

  body = {
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      hubProfile = {
        agentProfile = {
          vmSize = var.hub_vm_size
        }

        apiServerAccessProfile = {
          enablePrivateCluster = false
        }

        dnsPrefix = local.fleet_name
      }
    }

    tags = local.common_tags
  }

  response_export_values    = ["*"]
  schema_validation_enabled = false
}

resource "azapi_resource" "member" {
  for_each = local.member_clusters

  type      = "Microsoft.ContainerService/fleets/members@2025-03-01"
  name      = azurerm_kubernetes_cluster.member[each.key].name
  parent_id = azapi_resource.fleet.id

  body = {
    properties = {
      clusterResourceId = azurerm_kubernetes_cluster.member[each.key].id
      group             = each.value.group
    }
  }

  response_export_values    = ["*"]
  schema_validation_enabled = false
}

resource "azapi_resource" "upgrade_strategy" {
  type      = "Microsoft.ContainerService/fleets/updateStrategies@2026-02-01-preview"
  name      = "staged-rollout"
  parent_id = azapi_resource.fleet.id

  body = {
    properties = {
      strategy = {
        stages = [
          {
            afterStageWaitInSeconds = var.stage_wait_seconds
            groups = [
              {
                maxConcurrency = "1"
                name           = local.member_clusters.staging.group
              },
            ]
            maxConcurrency = "1"
            name           = "staging"
          },
          {
            afterStageWaitInSeconds = var.stage_wait_seconds
            groups = [
              {
                maxConcurrency = "1"
                name           = local.member_clusters.canary.group
              },
            ]
            maxConcurrency = "1"
            name           = "canary"
            afterGates = [
              {
                displayName = "Approve production rollout"
                type        = "Approval"
              },
            ]
          },
          {
            groups = [
              {
                maxConcurrency = "1"
                name           = local.member_clusters.production.group
              },
            ]
            maxConcurrency = "1"
            name           = "production"
          },
        ]
      }
    }
  }

  depends_on = [azapi_resource.member]

  response_export_values    = ["*"]
  schema_validation_enabled = false
}
