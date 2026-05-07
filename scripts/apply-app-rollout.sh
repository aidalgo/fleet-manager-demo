#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"
START_RUN="${1:-}" 

CRP_NAME="guestbook-crp"
ROLLOUT_NAME="guestbook-rollout-run"
ROLLOUT_STRATEGY_NAME="guestbook-rollout"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$ROOT_DIR/k8s/argocd/application.yaml"
kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$ROOT_DIR/k8s/fleet/crp.yaml"
kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f "$ROOT_DIR/k8s/fleet/app-rollout-strategy.yaml"

if [[ "$START_RUN" == "--start" ]]; then
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterstagedupdaterun "$ROLLOUT_NAME" --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub apply -f - <<EOF
apiVersion: placement.kubernetes-fleet.io/v1beta1
kind: ClusterStagedUpdateRun
metadata:
  name: $ROLLOUT_NAME
spec:
  placementName: $CRP_NAME
  stagedRolloutStrategyName: $ROLLOUT_STRATEGY_NAME
  state: Run
EOF
fi

kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub get clusterresourceplacement "$CRP_NAME"
