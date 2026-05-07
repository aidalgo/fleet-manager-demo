resource "azurerm_kubernetes_cluster" "member" {
  for_each = local.member_clusters

  name                = "${var.name_prefix}-${each.value.short_name}-${local.suffix}"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "${var.name_prefix}-${each.value.short_name}-${local.suffix}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  tags = merge(
    local.common_tags,
    {
      environment = each.value.environment
      fleet_group = each.value.group
    },
  )

  role_based_access_control_enabled = true

  default_node_pool {
    name       = "system"
    node_count = var.member_node_count
    os_sku     = var.node_os_sku
    vm_size    = var.member_node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}
