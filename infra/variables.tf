variable "subscription_id" {
  description = "Azure subscription ID used by both the azurerm and azapi providers."
  type        = string
}

variable "location" {
  description = "Azure region for the resource group, Fleet hub, and member clusters."
  type        = string
  default     = "eastus2"
}

variable "name_prefix" {
  description = "Short prefix used to name all demo resources."
  type        = string
  default     = "fleetdemo"
}

variable "kubernetes_version" {
  description = "Optional AKS version to pin for the member clusters. Leave null to use the regional default."
  type        = string
  default     = null
}

variable "member_node_vm_size" {
  description = "VM size for the member cluster system node pools."
  type        = string
  default     = "Standard_B2ms"
}

variable "member_node_count" {
  description = "Node count for each member cluster system node pool."
  type        = number
  default     = 1
}

variable "hub_vm_size" {
  description = "VM size for the Fleet hub cluster backing nodes."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_os_sku" {
  description = "OS SKU used for the AKS member cluster system node pools."
  type        = string
  default     = "AzureLinux"
}

variable "stage_wait_seconds" {
  description = "How long Azure Fleet waits between staged AKS upgrade groups."
  type        = number
  default     = 120
}

variable "tags" {
  description = "Extra tags applied to every Azure resource in the demo."
  type        = map(string)
  default     = {}
}
