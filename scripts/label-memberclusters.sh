#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infra"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

STAGING_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw staging_cluster_name)"
CANARY_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw canary_cluster_name)"
PRODUCTION_CLUSTER="$(terraform -chdir="$INFRA_DIR" output -raw production_cluster_name)"

verify_group() {
  local cluster_name="$1"
  local expected_group="$2"
  local actual_group

  actual_group="$(kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get membercluster "$cluster_name" -o go-template='{{ index .metadata.labels "fleet.azure.com/group" }}')"

  if [[ -z "$actual_group" ]]; then
    echo "MemberCluster $cluster_name is missing the built-in fleet.azure.com/group label." >&2
    exit 1
  fi

  if [[ "$actual_group" != "$expected_group" ]]; then
    echo "MemberCluster $cluster_name has fleet.azure.com/group=$actual_group, expected $expected_group." >&2
    exit 1
  fi
}

verify_group "$STAGING_CLUSTER" "staging"
verify_group "$CANARY_CLUSTER" "canary"
verify_group "$PRODUCTION_CLUSTER" "production"

echo "Azure Fleet manages MemberCluster labels on the hub. Verified built-in fleet.azure.com/group labels:"

kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get memberclusters --show-labels
