#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infra"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"
COMMAND="${1:-create}"
NAMESPACE_NAME="${FLEET_NAMESPACE_NAME:-managed-team-a}"
MEMBER_ARG="${2:-}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required." >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required." >&2
  exit 1
fi

RG="$(terraform -chdir="$INFRA_DIR" output -raw resource_group_name)"
FLEET="$(terraform -chdir="$INFRA_DIR" output -raw fleet_name)"
STAGING_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw staging_cluster_name)"
CANARY_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw canary_cluster_name)"
PRODUCTION_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw production_cluster_name)"

az extension add --name fleet --upgrade --only-show-errors >/dev/null

create_namespace() {
  az fleet namespace create \
    --resource-group "$RG" \
    --fleet-name "$FLEET" \
    --name "$NAMESPACE_NAME" \
    --labels "scenario=managed-fleet-namespaces owner=platform" \
    --annotations "app.kubernetes.io/part-of=fleet-manager-demo fleet-demo.azure.com/scenario=managed-fleet-namespaces" \
    --cpu-requests 100m \
    --cpu-limits 500m \
    --memory-requests 128Mi \
    --memory-limits 512Mi \
    --ingress-policy AllowSameNamespace \
    --egress-policy AllowAll \
    --delete-policy Keep \
    --adoption-policy Never \
    --member-cluster-names "$STAGING_CLUSTER" "$CANARY_CLUSTER" "$PRODUCTION_CLUSTER"
}

show_namespace() {
  az fleet namespace show \
    --resource-group "$RG" \
    --fleet-name "$FLEET" \
    --name "$NAMESPACE_NAME" \
    -o yaml
}

get_hub_credentials() {
  az fleet namespace get-credentials \
    --resource-group "$RG" \
    --fleet-name "$FLEET" \
    --name "$NAMESPACE_NAME" \
    --file "$KUBECONFIG_FILE" \
    --context "${NAMESPACE_NAME}-hub" \
    --overwrite-existing

  echo "Namespace kubeconfig context written: ${NAMESPACE_NAME}-hub"
}

get_member_credentials() {
  local member_name="$MEMBER_ARG"

  if [[ -z "$member_name" ]]; then
    member_name="$STAGING_CLUSTER"
  fi

  az fleet namespace get-credentials \
    --resource-group "$RG" \
    --fleet-name "$FLEET" \
    --name "$NAMESPACE_NAME" \
    --member "$member_name" \
    --file "$KUBECONFIG_FILE" \
    --context "${NAMESPACE_NAME}-${member_name}" \
    --overwrite-existing

  echo "Namespace kubeconfig context written: ${NAMESPACE_NAME}-${member_name}"
}

delete_namespace() {
  az fleet namespace delete \
    --resource-group "$RG" \
    --fleet-name "$FLEET" \
    --name "$NAMESPACE_NAME" \
    --yes
}

case "$COMMAND" in
  create)
    create_namespace
    ;;
  show)
    show_namespace
    ;;
  hub-credentials)
    get_hub_credentials
    ;;
  member-credentials)
    get_member_credentials
    ;;
  delete)
    delete_namespace
    ;;
  *)
    echo "Usage: $(basename "$0") [create|show|hub-credentials|member-credentials|delete] [member-name]" >&2
    exit 1
    ;;
esac