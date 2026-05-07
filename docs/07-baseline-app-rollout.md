---
title: 07. Baseline Argo App Rollout
nav_order: 70
description: Close the workshop with the advanced GitOps rollout where Argo CD reconciles the app and Fleet controls multi-cluster promotion.
permalink: /reference/baseline-app-rollout/
---

Status: Available

This is the advanced closing scenario in the repo. It shows how Azure
Kubernetes Fleet Manager fits alongside Argo CD rather than replacing it:

- Argo CD is the GitOps reconciler that applies the desired app state.
- Fleet stages that GitOps resource set on the hub, selects the member
  clusters, and controls how promotion moves from `staging` to `canary` to
  `production`.

It keeps the KubeFleet tutorial shape but simplifies the app flow:

- the Argo CD `Application` is staged in the standard `argocd` namespace
- the built-in `default` Argo CD project is used
- the sample app comes from `argoproj/argocd-example-apps`

Use this guide when you want to close the workshop with the most complete
end-to-end example of Fleet applied to a GitOps operating model. It builds on
the earlier Fleet-first scenarios and shows how those same control-plane ideas
fit under Argo-managed delivery.

## Shared prerequisites

- Complete `docs/01-infrastructure-setup.md`.
- Complete `docs/02-hub-bootstrap.md`.

## Repo assets used by this guide

- `k8s/argocd/application.yaml`
- `k8s/fleet/crp.yaml`
- `k8s/fleet/app-rollout-strategy.yaml`
- `scripts/bootstrap-argocd.sh`
- `scripts/apply-app-rollout.sh`
- `scripts/clear-app-rollout.sh`

## 1. Install Argo CD where this scenario needs it

```bash
./scripts/bootstrap-argocd.sh
```

What this does:

- Installs only Argo CD CRDs on the Fleet hub.
- Installs full Argo CD on each member cluster.

## 2. Confirm the hub-side MemberCluster labels

This repo's `ClusterResourcePlacement` selects member clusters by the built-in
`fleet.azure.com/group` label. Before starting the rollout flow, make sure those
labels exist on the hub-side `MemberCluster` objects:

```bash
./scripts/label-memberclusters.sh
kubectl --context fleet-hub get memberclusters --show-labels
```

Expected labels:

- `fleet.azure.com/group=staging`
- `fleet.azure.com/group=canary`
- `fleet.azure.com/group=production`

Azure Kubernetes Fleet Manager does not allow direct relabeling of
`MemberCluster` objects from the hub. This repo uses the built-in Fleet group
labels instead of custom `environment` labels.

## 3. Stage the Application and placement resources on the hub

```bash
./scripts/apply-app-rollout.sh
```

This applies:

- `k8s/argocd/application.yaml`
- `k8s/fleet/crp.yaml`
- `k8s/fleet/app-rollout-strategy.yaml`

## 4. Inspect the ClusterResourcePlacement

```bash
kubectl --context fleet-hub get clusterresourceplacement guestbook-crp -o yaml
```

Expected state before the rollout run:

- `Scheduled=True`
- the scheduling message reports `found 3 cluster(s)`
- rollout not started yet, because the CRP uses `strategy.type: External`

Important: `Scheduled=True` only means the scheduler evaluated the placement
policy successfully. It does not mean clusters were matched. If the message says
`found 0 cluster(s)`, the built-in Fleet group labels do not match the selector
in `k8s/fleet/crp.yaml` or the Fleet members are not yet ready.

## 5. Start the staged rollout

```bash
./scripts/apply-app-rollout.sh --start
kubectl --context fleet-hub get clusterstagedupdaterun guestbook-rollout-run -o yaml
```

The start script recreates `guestbook-rollout-run` and omits
`resourceSnapshotIndex` so Azure Fleet can create the latest resource snapshot
automatically for the external rollout. It creates the run with `state: Run`,
so execution starts immediately.

Expected order:

1. `staging`
2. `canary`
3. `production`

The strategy waits two minutes after `staging` and then requires manual
approval after `canary`.

## 6. Approve the production gate

After the `canary` stage completes, Fleet creates the approval request for the
gate before `production`:

```bash
kubectl --context fleet-hub get clusterapprovalrequests
```

Expected request name:

- `guestbook-rollout-run-after-canary`

Approve it by replacing the resource name if needed:

```bash
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
kubectl --context fleet-hub patch clusterapprovalrequests guestbook-rollout-run-after-canary \
  --type='merge' \
  -p "{\"status\":{\"conditions\":[{\"type\":\"Approved\",\"status\":\"True\",\"reason\":\"approved\",\"message\":\"approved\",\"lastTransitionTime\":\"$ts\",\"observedGeneration\":1}]}}" \
  --subresource=status
```

## 7. Verify Argo CD on the member clusters

```bash
kubectl --context member-staging -n argocd get applications
kubectl --context member-canary -n argocd get applications
kubectl --context member-production -n argocd get applications
```

Then verify the synced guestbook workload:

```bash
kubectl --context member-staging -n guestbook get all
kubectl --context member-canary -n guestbook get all
kubectl --context member-production -n guestbook get all
```

## 8. Reset the scenario

If you want to reset the staged app rollout and start again from step 3, run:

```bash
bash scripts/clear-app-rollout.sh
```

This removes the hub-side rollout objects and deletes the propagated
`guestbook-app` plus the `guestbook` namespace from each member cluster so the
next rollout starts from a clean slate.
