#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infra"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"

mkdir -p "$(dirname "$KUBECONFIG_FILE")"

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

az fleet get-credentials \
  --resource-group "$RG" \
  --name "$FLEET" \
  --file "$KUBECONFIG_FILE" \
  --context fleet-hub \
  --overwrite-existing

az aks get-credentials \
  --resource-group "$RG" \
  --name "$STAGING_CLUSTER" \
  --file "$KUBECONFIG_FILE" \
  --context member-staging \
  --overwrite-existing

az aks get-credentials \
  --resource-group "$RG" \
  --name "$CANARY_CLUSTER" \
  --file "$KUBECONFIG_FILE" \
  --context member-canary \
  --overwrite-existing

az aks get-credentials \
  --resource-group "$RG" \
  --name "$PRODUCTION_CLUSTER" \
  --file "$KUBECONFIG_FILE" \
  --context member-production \
  --overwrite-existing

echo "KUBECONFIG written to $KUBECONFIG_FILE"
echo "Export it before using kubectl:"
echo "export KUBECONFIG=$KUBECONFIG_FILE"
kubectl --kubeconfig "$KUBECONFIG_FILE" config get-contexts
