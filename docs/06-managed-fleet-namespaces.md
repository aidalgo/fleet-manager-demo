---
title: 06. Managed Fleet Namespaces
nav_order: 60
description: Create Azure-managed multi-cluster namespaces with quota, network policy, and scoped credentials.
permalink: /scenarios/managed-fleet-namespaces/
---

Status: Available

Preview feature.

This guide uses Managed Fleet Namespaces to create and govern one namespace
across multiple member clusters from Azure Fleet.

It covers quotas, default network-policy posture, adoption behavior, delete
behavior, and namespace-scoped access.

Argo CD is optional here. The namespace is managed by Fleet itself, and
workloads can be added later.

## Shared prerequisites

- Complete `docs/01-infrastructure-setup.md`.
- Complete `docs/02-hub-bootstrap.md`.

Argo CD is not required to create the managed namespace itself.

## Repo assets used by this scenario

- `scripts/apply-managed-fleet-namespaces.sh` as an optional shortcut after the manual walkthrough

## What this workshop demonstrates

Before the steps, it helps to define what a managed fleet namespace is in plain
language.

A managed fleet namespace is not just a normal Kubernetes `Namespace` manifest
that you apply with `kubectl`. It is an Azure Fleet resource that tells Fleet:
create and manage a namespace with the same name and governance settings across
selected member clusters.

That is why this scenario is different from `04` and `05`. In those demos, the
hub stages Kubernetes resources and Fleet places them. In this demo, Azure
Fleet itself is the source of truth for the namespace and its governance rules.

This workshop also introduces a few policy concepts that matter for operators:

- quotas define how much CPU and memory workloads in that namespace are allowed
  to request or consume on each cluster
- ingress and egress policies define the default network-policy posture for the
  namespace
- the adoption policy defines what Fleet should do if a namespace with the same
  name already exists on a member cluster
- the delete policy defines what should happen to the member-cluster namespace
  instances when the managed namespace resource is deleted

The last piece is namespace-scoped credentials. These are kubeconfig contexts
that grant access only to the managed namespace, either on the hub view or on a
specific member cluster. That makes them useful for team-scoped operations
without handing out full cluster-wide access.

That combination is the main teaching point of the demo:

1. Fleet can centrally create and govern one namespace across multiple member
   clusters.
2. Governance settings such as quotas and network posture travel with that
   namespace definition.
3. Lifecycle policies control how Fleet handles preexisting namespaces and
   teardown behavior.
4. Namespace-scoped credentials let teams inspect or use the namespace without
   needing broad cluster admin permissions.

If you are new to Fleet, a useful mental model is:

- a regular namespace is just a Kubernetes object in one cluster
- a managed fleet namespace is a Fleet-managed namespace definition for many clusters
- the Fleet resource defines the rules, and Fleet enforces those rules on each target cluster

## 1. Confirm the Fleet and member cluster names and set local variables

This walkthrough uses the same values the helper script uses, but shows them
explicitly so the user can see what Azure resources the commands target.

```bash
RG="$(terraform -chdir=infra output -raw resource_group_name)"
FLEET="$(terraform -chdir=infra output -raw fleet_name)"
STAGING_CLUSTER="$(terraform -chdir=infra output -raw staging_cluster_name)"
CANARY_CLUSTER="$(terraform -chdir=infra output -raw canary_cluster_name)"
PRODUCTION_CLUSTER="$(terraform -chdir=infra output -raw production_cluster_name)"
NAMESPACE_NAME="managed-team-a"
KUBECONFIG_FILE=".kube/fleet-demo.yaml"

printf '%s\n' "$RG" "$FLEET" "$STAGING_CLUSTER" "$CANARY_CLUSTER" "$PRODUCTION_CLUSTER"

az extension add --name fleet --upgrade --only-show-errors
```

Expected result:

- the resource group and fleet names resolve successfully
- the three member cluster names resolve successfully
- the Azure CLI `fleet` extension is installed or updated locally

## 2. Create the managed namespace

Create the managed namespace directly with Azure CLI:

```bash
az fleet namespace create \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  --labels "scenario=managed-fleet-namespaces owner=platform" \
  --annotations "app.kubernetes.io/part-of=fleet-manager-demo fleet-demo.azure.com/scenario=managed-fleet-namespaces" \
  --cpu-requests 100m \
  --cpu-limits 500m \
  --memory-requests 128Mi \
  --memory-limits 512Mi \
  --ingress-policy AllowSameNamespace \
  --egress-policy AllowAll \
  --delete-policy Keep \
  --adoption-policy Never \
  --member-cluster-names "$STAGING_CLUSTER" "$CANARY_CLUSTER" "$PRODUCTION_CLUSTER"
```

Important: quote the full value passed to `--labels` and `--annotations`.
With the current Fleet CLI extension, those flags are accepted reliably when
the space-separated `key=value` pairs are passed as one quoted string.

This creates a managed namespace named `managed-team-a` with:

- labels and annotations that identify the scenario
- CPU and memory quota settings
- `AllowSameNamespace` ingress
- `AllowAll` egress
- `Keep` delete policy
- `Never` adoption policy
- distribution to all three member clusters

If you already understand the command and want the shortcut path later, the
helper script runs the same create flow:

```bash
./scripts/apply-managed-fleet-namespaces.sh create
```

## 3. Inspect the managed namespace resource

```bash
az fleet namespace show \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  -o yaml
```

Expected state:

- the managed namespace exists as an Azure Fleet resource
- the output includes the namespace name `managed-team-a`
- the output shows the configured labels, annotations, quotas, and policies
- the output lists the targeted member clusters

Important: this is an Azure-managed preview feature, so creation and status
updates can take longer than the `kubectl`-only placement demos in `03`, `04`,
and `05`.

Shortcut path:

```bash
./scripts/apply-managed-fleet-namespaces.sh show
```

## 4. Get hub-scoped namespace credentials

```bash
az fleet namespace get-credentials \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  --file "$KUBECONFIG_FILE" \
  --context "${NAMESPACE_NAME}-hub" \
  --overwrite-existing

kubectl --kubeconfig "$KUBECONFIG_FILE" --context "${NAMESPACE_NAME}-hub" get resourcequota,networkpolicy
```

Expected result:

- a namespace-scoped kubeconfig context named `managed-team-a-hub` is written
- the hub-scoped context can inspect the managed namespace governance objects

This is the easiest way to show that access is scoped to the managed namespace
instead of handing out broad cluster-admin access.

Shortcut path:

```bash
./scripts/apply-managed-fleet-namespaces.sh hub-credentials
kubectl --kubeconfig .kube/fleet-demo.yaml --context managed-team-a-hub get resourcequota,networkpolicy
```

## 5. Get member-cluster credentials and inspect one cluster view

Start with the staging member cluster so the first example stays predictable:

```bash
az fleet namespace get-credentials \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  --member "$STAGING_CLUSTER" \
  --file "$KUBECONFIG_FILE" \
  --context "${NAMESPACE_NAME}-${STAGING_CLUSTER}" \
  --overwrite-existing

kubectl --kubeconfig "$KUBECONFIG_FILE" --context "${NAMESPACE_NAME}-${STAGING_CLUSTER}" get resourcequota,networkpolicy
```

If you want to inspect another target cluster, pass its member-cluster name as
the `--member` value directly:

```bash
az fleet namespace get-credentials \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  --member "$CANARY_CLUSTER" \
  --file "$KUBECONFIG_FILE" \
  --context "${NAMESPACE_NAME}-${CANARY_CLUSTER}" \
  --overwrite-existing
```

Expected result:

- a namespace-scoped kubeconfig context is written for the selected member cluster
- quotas and managed network policy objects are visible from that cluster-scoped namespace context
- the governance model is consistent across the targeted clusters

Shortcut path:

```bash
./scripts/apply-managed-fleet-namespaces.sh member-credentials
./scripts/apply-managed-fleet-namespaces.sh member-credentials "$CANARY_CLUSTER"
```

## 6. Pause and confirm the workshop outcome

Before you reset the scenario, make sure you can explain the result from three
different viewpoints.

From Azure Fleet, confirm that the managed namespace exists as a Fleet-managed
resource:

```bash
az fleet namespace show \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  -o yaml
```

From the hub-scoped namespace context you created earlier, confirm that the
governance objects are visible without broad cluster-admin access:

```bash
kubectl --kubeconfig "$KUBECONFIG_FILE" --context "${NAMESPACE_NAME}-hub" get resourcequota,networkpolicy
```

From the member-cluster namespace context you created earlier, confirm that one
target cluster sees the same governed namespace view:

```bash
kubectl --kubeconfig "$KUBECONFIG_FILE" --context "${NAMESPACE_NAME}-${STAGING_CLUSTER}" get resourcequota,networkpolicy
```

Expected result:

- Azure reports the managed namespace as a Fleet resource
- the hub-scoped context can inspect quotas and network policy objects
- the member-scoped context shows the same governed namespace behavior on a target cluster

If those three checks work, you have completed the main teaching goal of this
workshop: Azure Fleet is the source of truth for the namespace definition, and
teams can interact with it through namespace-scoped credentials instead of full
cluster-wide access.

## 7. Reset the scenario

If you want to rerun the workshop from the beginning, delete the managed
namespace resource:

```bash
az fleet namespace delete \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$NAMESPACE_NAME" \
  --yes
```

Because the namespace uses `delete-policy Keep`, treat this as a preview-feature
teardown step and verify the Azure-side cleanup before reusing the same demo
name immediately.

Shortcut path:

```bash
./scripts/apply-managed-fleet-namespaces.sh delete
```

## Implementation notes

- Keep this guide clearly labeled as preview in both the README and the doc title.
- Treat this as a platform capability, not as an application delivery pipeline.
- When workloads are later added to the managed namespace, document Argo as the delivery layer and Managed Fleet Namespaces as the governance layer.
