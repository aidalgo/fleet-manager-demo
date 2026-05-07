---
title: 04. Namespace Placement and Governance
nav_order: 40
description: Use ClusterResourcePlacement and ResourcePlacement to distribute namespaces, governance resources, and app config across the fleet.
permalink: /scenarios/namespace-governance/
---

Status: Available

This guide uses namespace placement to show how platform and application
responsibilities can be separated across the fleet.

It follows a clear split of responsibilities:

- the platform admin establishes the namespace boundary and governance baseline across the fleet
- the application team places namespace-scoped resources inside that boundary

Argo CD can still own the desired state staged on the hub, but this walkthrough
starts with direct `kubectl apply` steps so you can inspect the Fleet objects
and results directly.

## Shared prerequisites

- Complete `docs/01-infrastructure-setup.md`.
- Complete `docs/02-hub-bootstrap.md`.

## Repo assets used by this scenario

- `k8s/fleet/use-case-1/kustomization.yaml`
- `k8s/fleet/use-case-1/namespace.yaml`
- `k8s/fleet/use-case-1/namespace-crp.yaml`
- `k8s/fleet/use-case-1/resourcequota.yaml`
- `k8s/fleet/use-case-1/limitrange.yaml`
- `k8s/fleet/use-case-1/networkpolicy.yaml`
- `k8s/fleet/use-case-1/governance-placement.yaml`
- `k8s/fleet/use-case-1/configmap.yaml`
- `k8s/fleet/use-case-1/resource-placement.yaml`
- `scripts/apply-namespace-placement.sh`

## What this workshop demonstrates

Before the steps, it helps to define the two Fleet objects used in this demo in
plain language.

`ClusterResourcePlacement` is a hub-side Fleet object that answers this
question: "Which clusters should get this resource?" In this workshop, the
resource is the namespace itself. That means the platform admin uses one
`ClusterResourcePlacement` to tell Fleet: create the namespace `team-a-demo` on
all three member clusters.

`ResourcePlacement` is similar, but it is scoped to one namespace and is meant
for the resources inside that namespace. It answers this question: "Inside this
namespace, which resources should be copied to which clusters?" In this
workshop, the platform admin uses one `ResourcePlacement` to push the
governance baseline everywhere, and the application team uses another
`ResourcePlacement` to send only its ConfigMap to `staging` and `canary`.

That distinction is the main teaching point of the demo:

1. The platform admin uses `ClusterResourcePlacement` to establish the
   namespace boundary across the fleet.
2. The platform admin uses a namespace-scoped `ResourcePlacement` to distribute
   the governance baseline to every member cluster.
3. The application team uses a separate `ResourcePlacement` to distribute a
   specific namespace-scoped resource only to the allowed subset.
4. Optional namespace-accessible status reporting lets namespace owners inspect
   placement results without needing broad cluster-wide access.

If you are new to Fleet, a useful mental model is:

- `ClusterResourcePlacement` is the fleet-wide placement policy
- `ResourcePlacement` is the namespace-level placement policy inside a boundary
- one namespace can have more than one `ResourcePlacement`
- the first creates the shared space, then additional placements decide which
   governance objects and app content go into that space on each target cluster

In the concrete example shipped in this repo:

- the namespace `team-a-demo` is created on all three member clusters
- the governance baseline goes to all three member clusters
- the governance baseline consists of a `ResourceQuota`, a `LimitRange`, and a same-namespace ingress `NetworkPolicy`
- the ConfigMap `app-team-settings` is placed only on `staging` and `canary`
- `production` gets the namespace boundary, but not the app-team config

## 1. Confirm the hub-side MemberCluster labels

This scenario selects member clusters by the built-in
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

Azure Kubernetes Fleet Manager does not allow direct relabeling of
`MemberCluster` objects from the hub. This repo uses the built-in Fleet group
labels instead of custom `environment` labels.

## 2. Apply the platform-admin side on the hub

```bash
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/namespace.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/namespace-crp.yaml
```

What this does:

- creates the `team-a-demo` namespace on the hub
- creates `team-a-namespace-crp`
- tells Fleet to establish that namespace on `staging`, `canary`, and `production`

## 3. Inspect the namespace placement before moving on

```bash
kubectl --context fleet-hub get clusterresourceplacement team-a-namespace-crp -o yaml
```

Expected state:

- the placement is scheduled successfully
- the placement targets three member clusters
- `statusReportingScope: NamespaceAccessible` is enabled for the namespace setup

Important: this step only establishes the namespace boundary. The app-team
resource and governance baseline are not placed yet.

## 4. Wait until the namespace exists on each member cluster

```bash
kubectl --context member-staging get namespace team-a-demo
kubectl --context member-canary get namespace team-a-demo
kubectl --context member-production get namespace team-a-demo
```

Expected result:

- `team-a-demo` exists on all three member clusters
- there is still no governance baseline or app-team ConfigMap on any member cluster yet

`selectionScope: NamespaceOnly` is still a preview surface in the Fleet
`v1beta1` API, so this is the checkpoint where you confirm the namespace setup
worked before continuing.

## 5. Apply the platform governance baseline on the hub

```bash
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/resourcequota.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/limitrange.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/networkpolicy.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/governance-placement.yaml
```

What this does:

- creates the hub-side `ResourceQuota` named `team-a-quota`
- creates the hub-side `LimitRange` named `team-a-default-limits`
- creates the hub-side `NetworkPolicy` named `team-a-allow-same-namespace-ingress`
- creates the namespace-scoped `ResourcePlacement` named `team-a-governance-rp`
- tells Fleet to push that governance pack to `staging`, `canary`, and `production`

## 6. Inspect the governance ResourcePlacement

```bash
kubectl --context fleet-hub get resourceplacement team-a-governance-rp -n team-a-demo -o yaml
```

Expected state:

- the placement selects the governance resources inside `team-a-demo`
- all three member clusters are targeted
- the governance baseline is managed separately from app-team content

## 7. Verify the governance baseline on the member clusters

```bash
kubectl --context member-staging -n team-a-demo get resourcequota,limitrange,networkpolicy
kubectl --context member-canary -n team-a-demo get resourcequota,limitrange,networkpolicy
kubectl --context member-production -n team-a-demo get resourcequota,limitrange,networkpolicy
```

Expected result:

- `team-a-quota` exists on all three member clusters
- `team-a-default-limits` exists on all three member clusters
- `team-a-allow-same-namespace-ingress` exists on all three member clusters

This is the GitOps namespace-governance part of the demo: the platform team is
using ordinary Kubernetes objects plus Fleet placements to create a consistent
baseline everywhere.

## 8. Apply the app-team resource and ResourcePlacement

```bash
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/configmap.yaml
kubectl --context fleet-hub apply -f k8s/fleet/use-case-1/resource-placement.yaml
```

What this does:

- creates the hub-side ConfigMap `app-team-settings` in `team-a-demo`
- creates the namespace-scoped `ResourcePlacement` named `team-a-config-rp`
- tells Fleet to distribute only that ConfigMap to `staging` and `canary`

## 9. Inspect the app-team ResourcePlacement

```bash
kubectl --context fleet-hub get resourceplacement team-a-config-rp -n team-a-demo -o yaml
```

Expected state:

- the placement selects the ConfigMap by label
- only `staging` and `canary` are targeted
- `production` is not part of the app-team placement policy

Important: `production` not receiving the ConfigMap is the expected success
condition for this demo.

## 10. Verify the split of responsibilities on the member clusters

```bash
kubectl --context member-staging -n team-a-demo get configmap app-team-settings
kubectl --context member-canary -n team-a-demo get configmap app-team-settings
kubectl --context member-production -n team-a-demo get configmap app-team-settings
```

Expected result:

- the ConfigMap exists on `member-staging`
- the ConfigMap exists on `member-canary`
- the ConfigMap does not exist on `member-production`

That is the core story of this workshop:

- the platform admin established the namespace everywhere
- the platform admin distributed the governance baseline everywhere
- the application team distributed only its selected resource to the allowed subset

If you want the full picture in one screen, also inspect the namespace plus the
governance objects plus the app-team ConfigMap together:

```bash
kubectl --context member-staging -n team-a-demo get resourcequota,limitrange,networkpolicy,configmap
kubectl --context member-canary -n team-a-demo get resourcequota,limitrange,networkpolicy,configmap
kubectl --context member-production -n team-a-demo get resourcequota,limitrange,networkpolicy,configmap
```

## 11. How this maps to a GitOps flow

For a GitOps workflow, keep the hub-side manifests in Git and let Argo CD sync
them to the Fleet hub.

The starting point in this repo is `k8s/fleet/use-case-1/`.

The simplest first step is to create an Argo CD `Application` that targets
`k8s/fleet/use-case-1/` and syncs that folder to the Fleet hub context.

In that model:

- Argo CD owns the desired state on the Fleet hub
- Fleet still creates the namespace boundary on the member clusters
- Fleet still distributes the governance baseline to all three clusters
- Fleet still distributes the app-team ConfigMap only to `staging` and `canary`

That means Argo CD is the writer to the hub, while Fleet remains responsible
for multi-cluster distribution and policy enforcement.

Important: this walkthrough applies the namespace first, confirms that it has
been created on each member cluster, and only then applies the namespace-
scoped placements. The current `k8s/fleet/use-case-1/kustomization.yaml`
collects the same manifests, but it does not encode that dependency by itself.

To make the GitOps path in this repo stronger, consider these improvements:

- split the scenario into two folders or two Argo CD Applications: one for the namespace plus `ClusterResourcePlacement`, and one for the governance and app-team resources
- add Argo CD sync-wave annotations so namespace setup happens before the namespace-scoped placements
- keep platform-owned manifests and app-team manifests in separate folders so ownership stays clear in Git

Those changes would make the GitOps path easier to understand and closer to the
manual walkthrough order.

## 12. Reset the scenario

To rerun the scenario from the beginning, clear the hub-side and member-side
resources:

```bash
./scripts/apply-namespace-placement.sh delete
```

This removes:

- the hub-side namespace `team-a-demo`
- `team-a-namespace-crp`
- `team-a-governance-rp`
- the hub-side `ResourceQuota`, `LimitRange`, and `NetworkPolicy`
- the hub-side ConfigMap `app-team-settings`
- `team-a-config-rp`
- the propagated namespace, governance objects, and ConfigMap from the member clusters

## Implementation notes

- Reuse the built-in Fleet group labels rather than attempting to relabel `MemberCluster` objects directly.
- Keep Argo as the GitOps writer to the hub for this pattern. Fleet remains responsible for distributing the namespace, the governance baseline, and the selected app resources across clusters.
