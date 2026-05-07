output "resource_group_name" {
  description = "Resource group that contains the Fleet demo infrastructure."
  value       = azurerm_resource_group.demo.name
}

output "fleet_name" {
  description = "Azure Kubernetes Fleet Manager name."
  value       = local.fleet_name
}

output "fleet_id" {
  description = "Resource ID of the Fleet hub resource."
  value       = azapi_resource.fleet.id
}

output "fleet_update_strategy_name" {
  description = "Update strategy name for staged AKS upgrades."
  value       = azapi_resource.upgrade_strategy.name
}

output "member_cluster_names" {
  description = "Member AKS cluster names keyed by environment."
  value = {
    for env, cluster in azurerm_kubernetes_cluster.member : env => cluster.name
  }
}

output "staging_cluster_name" {
  description = "Staging AKS member cluster name."
  value       = azurerm_kubernetes_cluster.member["staging"].name
}

output "canary_cluster_name" {
  description = "Canary AKS member cluster name."
  value       = azurerm_kubernetes_cluster.member["canary"].name
}

output "production_cluster_name" {
  description = "Production AKS member cluster name."
  value       = azurerm_kubernetes_cluster.member["production"].name
}

output "member_cluster_ids" {
  description = "Member AKS cluster resource IDs keyed by environment."
  value = {
    for env, cluster in azurerm_kubernetes_cluster.member : env => cluster.id
  }
}

output "fleet_member_resource_ids" {
  description = "Fleet member resource IDs keyed by environment."
  value = {
    for env, member in azapi_resource.member : env => member.id
  }
}

output "hub_credentials_command" {
  description = "CLI command to download hub cluster credentials after apply."
  value       = "az fleet get-credentials --resource-group ${azurerm_resource_group.demo.name} --name ${local.fleet_name} --overwrite-existing"
}

output "member_credentials_commands" {
  description = "CLI commands to download each member cluster kubeconfig after apply."
  value = {
    for env, cluster in azurerm_kubernetes_cluster.member : env => "az aks get-credentials --resource-group ${azurerm_resource_group.demo.name} --name ${cluster.name} --overwrite-existing"
  }
}

output "fleet_hub_rbac_note" {
  description = "Reminder about the RBAC role required to use kubectl against the Fleet hub cluster."
  value       = "Assign the 'Azure Kubernetes Fleet Manager RBAC Cluster Admin' role on the Fleet resource before using hub kubeconfig commands."
}

