#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_FILE="${KUBECONFIG:-$ROOT_DIR/.kube/fleet-demo.yaml}"
HUB_CONTEXT="fleet-hub"
MEMBER_CONTEXTS=(member-staging member-canary member-production)

if [[ ! -f "$KUBECONFIG_FILE" ]]; then
  echo "Missing kubeconfig file at $KUBECONFIG_FILE. Run scripts/get-credentials.sh first." >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required." >&2
  exit 1
fi

kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$HUB_CONTEXT" create namespace argocd --dry-run=client -o yaml | \
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$HUB_CONTEXT" apply -f -

kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$HUB_CONTEXT" apply -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable --server-side=true

for context in "${MEMBER_CONTEXTS[@]}"; do
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" create namespace argocd --dry-run=client -o yaml | \
    kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" apply -f -

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" -n argocd apply --server-side=true --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" -n argocd rollout status deploy/argocd-server --timeout=10m
  kubectl --kubeconfig "$KUBECONFIG_FILE" --context "$context" -n argocd rollout status deploy/argocd-repo-server --timeout=10m
done

echo "Argo CD is installed on all member clusters, and only CRDs are staged on the hub cluster."
