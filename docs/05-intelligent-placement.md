---
title: 05. Intelligent Placement
nav_order: 50
description: Use PickN, affinity, and property sorting to see how Fleet chooses member clusters for a workload.
permalink: /scenarios/intelligent-placement/
---

Status: Available

This guide focuses on scheduling decisions. It shows how Fleet can place one
workload from the hub onto a selected subset of member clusters instead of
broadcasting it everywhere.

Argo CD can still stage the desired workload on the hub, but this walkthrough
starts with direct `kubectl apply` steps so you can inspect the scheduling
decision directly. The workload exists once on the hub, and Fleet decides
which member clusters should receive it.

## Shared prerequisites

- Complete `docs/01-infrastructure-setup.md`.
- Complete `docs/02-hub-bootstrap.md`.

## Repo assets used by this scenario

- `k8s/fleet/use-case-2/kustomization.yaml`
- `k8s/fleet/use-case-2/namespace.yaml`
- `k8s/fleet/use-case-2/service.yaml`
- `k8s/fleet/use-case-2/deployment.yaml`
- `k8s/fleet/use-case-2/crp-pickn.yaml`

## What this workshop demonstrates

Before the steps, it helps to define the main Fleet concepts used in this demo
in plain language.

This workshop uses a `ClusterResourcePlacement`, which is the Fleet object that
decides where a resource should go across the fleet. In this scenario, it is
the object that makes the scheduling decision for the namespace and the
namespace-scoped workload staged on the hub.

`PickN` means "choose exactly N member clusters from the eligible set." In this
demo, `N` is `2`, so Fleet must select exactly two clusters instead of sending
the workload to all three.

The placement policy has two layers of decision-making:

- the required selector defines which clusters are allowed to participate at all
- the preferred selectors assign higher scores to the clusters Fleet should try first

In this repo, the required selector says that `staging`, `canary`, and
`production` are all valid candidates. The preferred selectors then say: prefer
`canary` more strongly than `production`. That means `staging` stays eligible,
but it acts more like a fallback option.

This demo also uses a property sorter. A property sorter is a Fleet rule that
orders matching clusters by one of their reported properties. Here, the policy
uses `kubernetes-fleet.io/node-count` with descending order, which means Fleet
prefers the larger cluster first when it is comparing clusters inside the same
preference bucket.

That combination is the main teaching point of the demo:

1. `PickN` placement chooses a subset instead of broadcasting everywhere.
2. Required selectors define the eligible pool.
3. Preferred selectors and property sorters influence which eligible clusters
   Fleet picks first.
4. GitOps can still stage the workload on the hub while Fleet remains the
   scheduler that decides the targets.

If you are new to Fleet, a useful mental model is:

- the hub stores the workload once
- `ClusterResourcePlacement` is the scheduling policy
- `PickN` says how many targets to choose
- label selectors and property sorters explain why one cluster was chosen over another

Concrete behavior in this repo:

- use `PickN` to place the namespace and workload onto two of the three member clusters
- consider all three built-in Fleet groups as eligible candidates
- weight `canary` higher than `production`, and leave `staging` with no preference weight
- use `kubernetes-fleet.io/node-count` as the property sorter inside each weighted preference term

## 1. Confirm the hub-side MemberCluster labels

This scenario selects eligible member clusters by the built-in
`fleet.azure.com/group` label. Before starting the walkthrough, make sure those
labels exist on the hub-side `MemberCluster` objects:

```bash
./scripts/label-memberclusters.sh
kubectl --context fleet-hub get memberclusters --show-labels
```

Expected labels:

- `fleet.azure.com/group=staging`
- `fleet.azure.com/group=canary`
- `fleet.azure.com/group=production`

## 2. Stage the workload on the hub

```bash
kubectl --context fleet-hub apply -f k8s/fleet/use-case-2/namespace.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-2/service.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-2/deployment.yaml
```

What this does:

- creates the namespace `intelligent-demo` on the hub
- stages the Service `nginx-service` on the hub
- stages the Deployment `nginx-deployment` on the hub

At this point, the workload exists only on the hub. Nothing has been scheduled
to the member clusters yet.

## 3. Apply the `PickN` placement policy

```bash
kubectl --context fleet-hub apply -f k8s/fleet/use-case-2/crp-pickn.yaml
```

What this does:

- creates `intelligent-demo-crp`
- makes all three built-in Fleet groups eligible candidates
- tells Fleet to select exactly two clusters
- prefers `canary` first and `production` second
- uses `kubernetes-fleet.io/node-count` as the property sorter inside each preferred term

The CRP selects the namespace `intelligent-demo`, so the namespace-scoped
workload staged inside that namespace travels with the selected namespace.

## 4. Inspect the placement decision on the hub

```bash
kubectl --context fleet-hub describe clusterresourceplacement intelligent-demo-crp
```

Expected state:

- the placement is scheduled successfully
- all three member clusters are eligible by required label matching
- Fleet chooses two targets because `numberOfClusters: 2`
- `canary` and `production` should be favored by the preference weights

Important: `Scheduled=True` means the scheduler evaluated the policy
successfully. The detailed placement status is what tells you which clusters
were actually selected.

## 5. Verify which member clusters received the workload

Before you run the checks below, decide what success looks like. This workshop
is not trying to place the workload on all three clusters. One cluster should
be left out on purpose. That means one of the commands below may return
`NotFound`, and that is an expected teaching outcome, not a failure.

```bash
kubectl --context member-staging get namespace intelligent-demo
kubectl --context member-canary get namespace intelligent-demo
kubectl --context member-production get namespace intelligent-demo

kubectl --context member-staging -n intelligent-demo get deployment,service,pods
kubectl --context member-canary -n intelligent-demo get deployment,service,pods
kubectl --context member-production -n intelligent-demo get deployment,service,pods
```

Expected result:

- the workload is placed on two member clusters, not all three
- `canary` and `production` should usually be the selected targets in this demo
- the remaining cluster should intentionally show that it was not selected,
  either because the namespace is absent or because the staged workload is not present there

If cluster properties tie or member availability changes, trust the CRP status
on the hub to explain the final scheduling result.

## 6. How this maps to a GitOps flow

For a GitOps workflow, keep the hub-side manifests in Git and let Argo CD sync
them to the Fleet hub.

The starting point in this repo is `k8s/fleet/use-case-2/`.

The simplest first step is to create an Argo CD `Application` that targets
`k8s/fleet/use-case-2/` and syncs that folder to the Fleet hub context.

In that model:

- Argo CD owns the desired state on the Fleet hub
- Fleet evaluates the `PickN` placement policy on the hub
- Fleet selects two member clusters from the eligible set
- Fleet propagates the namespace and workload only to the selected clusters

That means Argo CD is the writer to the hub, while Fleet remains responsible
for scheduling and multi-cluster distribution.

This scenario maps more directly to GitOps than the namespace-governance
scenario because the namespace, workload, and placement policy all live in one
folder and do not depend on a separate wait step across member clusters.

To make the GitOps path in this repo stronger, consider these improvements:

- separate the staged workload manifests from the placement policy if different teams should own them in Git
- add Argo CD sync-wave annotations if you want the namespace to be applied ahead of the namespace-scoped workload more explicitly
- add a small Argo CD example `Application` manifest for this scenario so the GitOps entry point is visible in the repo

## 7. Reset the scenario

If you want to rerun the workshop from the beginning, clear the hub-side and
member-side resources:

```bash
./scripts/apply-intelligent-placement.sh delete
```

This removes:

- `intelligent-demo-crp`
- the hub-side `nginx-service` and `nginx-deployment`
- the hub-side namespace `intelligent-demo`
- the propagated namespace and workload from the member clusters

## Implementation notes

- Keep the first implementation single-region and cheap. Labels and properties tell the story well enough without introducing new Azure regions.
- If the repo later adds a second region, extend this guide with topology spread constraints keyed on `fleet.azure.com/location`.
- Reuse the baseline rollout guide as the delivery reference and make this guide about scheduling decisions rather than staged approvals.
