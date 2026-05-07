#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"
SCENARIO_DIR="$ROOT_DIR/k8s/fleet/use-case-1"
COMMAND="${1:-apply}"
NAMESPACE_NAME="team-a-demo"
CRP_NAME="team-a-namespace-crp"
GOVERNANCE_RP_NAME="team-a-governance-rp"
APP_RP_NAME="team-a-config-rp"
MEMBER_CONTEXTS=(member-staging member-canary member-production)

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

wait_for_namespace() {
  local context="$1"
  local attempts=30

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
      return 0
    fi

    sleep 5
  done

  echo "Timed out waiting for namespace $NAMESPACE_NAME on $context." >&2
  return 1
}

apply_scenario() {
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/namespace.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/namespace-crp.yaml"

  for member_context in "${MEMBER_CONTEXTS[@]}"; do
    wait_for_namespace "$member_context"
  done

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/resourcequota.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/limitrange.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/networkpolicy.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/governance-placement.yaml"

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/configmap.yaml"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$SCENARIO_DIR/resource-placement.yaml"

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get clusterresourceplacement "$CRP_NAME"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get resourceplacement "$GOVERNANCE_RP_NAME" -n "$NAMESPACE_NAME"
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get resourceplacement "$APP_RP_NAME" -n "$NAMESPACE_NAME"
}

delete_scenario() {
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete resourceplacement "$APP_RP_NAME" -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete resourceplacement "$GOVERNANCE_RP_NAME" -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete configmap app-team-settings -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete networkpolicy team-a-allow-same-namespace-ingress -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete limitrange team-a-default-limits -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete resourcequota team-a-quota -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterresourceplacement "$CRP_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete namespace "$NAMESPACE_NAME" --ignore-not-found --wait=true

  for member_context in "${MEMBER_CONTEXTS[@]}"; do
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete configmap app-team-settings -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete networkpolicy team-a-allow-same-namespace-ingress -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete limitrange team-a-default-limits -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete resourcequota team-a-quota -n "$NAMESPACE_NAME" --ignore-not-found --wait=true
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