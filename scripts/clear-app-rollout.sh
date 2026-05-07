#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterstagedupdaterun guestbook-rollout-run --ignore-not-found --wait=true
kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterresourceplacement guestbook-crp --ignore-not-found --wait=true
kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete clusterstagedupdatestrategy guestbook-rollout --ignore-not-found --wait=true
kubectl --kubeconfig "$KUBECONFIG_FILE" --context fleet-hub delete application guestbook-app -n argocd --ignore-not-found --wait=true

for member_context in member-staging member-canary member-production; do
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete application guestbook-app -n argocd --ignore-not-found --wait=true
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$member_context" delete namespace guestbook --ignore-not-found --wait=true
done