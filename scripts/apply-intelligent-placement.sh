#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"
SCENARIO_DIR="$ROOT_DIR/k8s/fleet/use-case-2"
COMMAND="${1:-apply}"
NAMESPACE_NAME="intelligent-demo"
CRP_NAME="intelligent-demo-crp"
MEMBER_CONTEXTS=(member-staging member-canary member-production)

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

apply_scenario() {
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/namespace.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/service.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/deployment.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/crp-pickn.yaml"

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get clusterresourceplacement "$CRP_NAME"
}

delete_scenario() {
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterresourceplacement "$CRP_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete service nginx-service -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete deployment nginx-deployment -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete namespace "$NAMESPACE_NAME" --ignore-not-found --wait=true

  for member_context in "${MEMBER_CONTEXTS[@]}"; do
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete service nginx-service -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete deployment nginx-deployment -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete namespace "$NAMESPACE_NAME" --ignore-not-found --wait=true
  done
}

case "$COMMAND" in
  apply)
    apply_scenario
    ;;
  delete)
    delete_scenario
    ;;
  *)
    echo "Usage: $(basename "$0") [apply|delete]" >&2
    exit 1
    ;;
esac