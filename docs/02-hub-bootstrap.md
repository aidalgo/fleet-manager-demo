---
title: 02. Hub Bootstrap
nav_order: 20
description: Prepare Fleet hub access, kubeconfigs, and member labels for the workshop tracks.
permalink: /setup/hub-bootstrap/
---

This doc prepares access to the Fleet hub and member clusters. It intentionally
stops short of installing Argo CD everywhere so that Argo-dependent and
non-Argo scenarios can diverge cleanly.

## 1. Grant yourself Fleet hub RBAC

Before using `kubectl` against the Fleet hub, assign yourself the `Azure Kubernetes Fleet Manager RBAC Cluster Admin` role on the Fleet resource:

```bash
USER_ID=$(az ad signed-in-user show --query id -o tsv)
FLEET_ID=$(terraform -chdir=infra output -raw fleet_id)

az role assignment create \
  --assignee-object-id "$USER_ID" \
  --assignee-principal-type User \
  --role "Azure Kubernetes Fleet Manager RBAC Cluster Admin" \
  --scope "$FLEET_ID"
```

If your account cannot create role assignments, ask a subscription or
resource-group administrator to run the command for you. Wait briefly for role
propagation before continuing.

## 2. Download kubeconfigs into a local demo file

```bash
./scripts/get-credentials.sh
export KUBECONFIG="$PWD/.kube/fleet-demo.yaml"
```

This creates four contexts:

- `fleet-hub`
- `member-staging`
- `member-canary`
- `member-production`

## 3. Verify the hub-side Fleet group labels

```bash
./scripts/label-memberclusters.sh
kubectl --context fleet-hub get memberclusters --show-labels
```

Expected built-in labels:

- `fleet.azure.com/group=staging`
- `fleet.azure.com/group=canary`
- `fleet.azure.com/group=production`

Azure Kubernetes Fleet Manager does not allow direct modification of
`MemberCluster` labels through the hub cluster. This repo uses the built-in
Fleet group labels that come from the Fleet member group assignments created in
Terraform.

## 4. Choose the workshop track you want to run next

At this point, the shared platform setup is complete. Continue with the
scenario that matches what you want to run next:

- Continue to `docs/03-update-orchestration.md` for staged AKS updates and
  approval-gated rollout.
- Continue to `docs/04-namespace-placement.md` for namespace placement and
  governance.
- Continue to `docs/05-intelligent-placement.md` for PickN scheduling and
  cluster selection.
- Continue to `docs/06-managed-fleet-namespaces.md` for Azure-managed
  multi-cluster namespaces.
- Continue to `docs/07-baseline-app-rollout.md` and run
  `./scripts/bootstrap-argocd.sh` for the Argo CD rollout scenario.

## 5. Verify hub access

```bash
kubectl --context fleet-hub get memberclusters
kubectl --context member-staging get ns
kubectl --context member-canary get ns
kubectl --context member-production get ns
```

Expected result:

- the hub context can list Fleet member clusters
- each member-cluster context responds to a basic namespace query
- you can now move into any of the scenario guides without needing more shared setup

If one of the contexts fails here, fix that before moving into a scenario.
Otherwise, leave the `KUBECONFIG` export in place and continue directly to your
chosen workshop track.

## RBAC reminder

If `kubectl --context fleet-hub` still fails with authorization errors after the
role assignment, wait for propagation and retry.
