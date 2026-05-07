---
title: 07. AKS Update Orchestration
nav_order: 70
description: Run staged AKS updates through Fleet strategies, approval gates, and auto-upgrade profiles.
permalink: /operations/update-orchestration/
---

Status: Available for staged node-image updates with a canary-to-production
approval gate. Auto-upgrade profiles are also included as a hands-on extension.

This is the fleet-operations track for the repo. Unlike the Argo delivery
scenarios, this guide operates directly against AKS member clusters through
Azure Fleet update strategies, update runs, and auto-upgrade profiles.

## Shared prerequisites

- Complete `docs/01-infrastructure-setup.md`.
- Complete `docs/02-hub-bootstrap.md`.
- Install or update the Azure CLI `fleet` extension.
- If your environment was provisioned before the approval-gated strategy was
  added to this repo, rerun `terraform apply` in `infra/` first so the latest
  update strategy is present in Azure.

Argo CD is not required for this scenario.

## Repo assets used by this guide

- `infra/fleet.tf`
- `scripts/get-credentials.sh`

## What this workshop demonstrates

Before the steps, it helps to define the three Fleet update concepts used in
this workshop in plain language.

An update strategy is the reusable rollout template. It defines the order of
stages, the update groups in each stage, the wait time between stages, the
maximum concurrency, and any approval gates.

An update run is one execution of that strategy against real clusters. It is the
thing you create, start, watch, stop, or skip.

An auto-upgrade profile is the recurring automation rule. It says when Fleet
should automatically create update runs in the future when new Kubernetes or
node image releases appear.

The strategy in this repo now teaches a conservative production rollout:

1. `staging` updates first.
2. `canary` updates second.
3. A manual approval gate pauses the run before `production`.
4. `production` updates only after that approval is granted.

If you are new to Fleet, a useful mental model is:

- update strategy = rollout template
- update run = one execution of that template
- auto-upgrade profile = recurring trigger that can generate future runs

## 1. Gather the Azure values

```bash
RG=$(terraform -chdir=infra output -raw resource_group_name)
FLEET=$(terraform -chdir=infra output -raw fleet_name)
FLEET_ID=$(terraform -chdir=infra output -raw fleet_id)
STRATEGY=$(terraform -chdir=infra output -raw fleet_update_strategy_name)
STAGING_CLUSTER=$(terraform -chdir=infra output -raw staging_cluster_name)
CANARY_CLUSTER=$(terraform -chdir=infra output -raw canary_cluster_name)
PRODUCTION_CLUSTER=$(terraform -chdir=infra output -raw production_cluster_name)

az extension add --name fleet --upgrade --only-show-errors
```

## 2. Inspect the current cluster versions and node images

```bash
for cluster in "$STAGING_CLUSTER" "$CANARY_CLUSTER" "$PRODUCTION_CLUSTER"; do
  az aks show -g "$RG" -n "$cluster" \
    --query "{name:name,controlPlane:kubernetesVersion,nodeImage:agentPoolProfiles[0].nodeImageVersion}" \
    -o table
done
```

This is your before-state snapshot for the workshop.

## 3. Inspect the Fleet update strategy before starting a run

```bash
az resource show \
  --ids "$FLEET_ID/updateStrategies/$STRATEGY" \
  --api-version 2026-02-01-preview \
  -o yaml
```

Expected strategy behavior:

- the strategy contains three stages: `staging`, `canary`, and `production`
- `maxConcurrency` is set to `1` at both the stage and group levels for a safe rollout
- a pause is configured between earlier stages
- the `canary` stage creates an approval gate before `production` can start

This is the reusable policy that both manual update runs and auto-upgrade
profiles will follow.

## 4. Create the staged node-image update run

```bash
az fleet updaterun create \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo \
  --upgrade-type NodeImageOnly \
  --node-image-selection Latest \
  --update-strategy-name "$STRATEGY"
```

What this does:

- creates an update run named `node-image-demo`
- uses the staged Fleet strategy stored in Terraform
- upgrades only the node image, not the Kubernetes version
- chooses the latest region-available node image when each cluster begins its upgrade

## 5. Start the run

```bash
az fleet updaterun start \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo
```

## 6. Watch the run until it reaches the approval gate

```bash
az fleet updaterun show \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo \
  -o yaml
```

Expected order:

1. `staging`
2. `canary`
3. pause before `production`

Expected behavior:

- `staging` starts first
- `canary` starts only after the earlier stage rules are satisfied
- once `canary` completes, the run pauses and waits for approval before `production`

For a UI view of the same state, open the Fleet Manager resource in the Azure
portal and go to Multi-cluster update.

## 7. Approve the production gate

For this workshop, use the Azure portal approval flow:

1. Open the Fleet Manager resource in the Azure portal.
2. Go to Multi-cluster update.
3. Open the `node-image-demo` run.
4. Find the pending gate after `canary`.
5. Approve the gate named `Approve production rollout`.

This is the human promotion step in the rollout. It is where an operator checks
that `staging` and `canary` look healthy before allowing `production` to move.

## 8. Recheck the run after approval

```bash
az fleet updaterun show \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo \
  -o table
```

Expected result:

- the run progresses into `production` after approval
- the run eventually reaches `Completed` if no cluster upgrade fails

## 9. Verify the post-update cluster state

```bash
for cluster in "$STAGING_CLUSTER" "$CANARY_CLUSTER" "$PRODUCTION_CLUSTER"; do
  az aks show -g "$RG" -n "$cluster" \
    --query "{name:name,controlPlane:kubernetesVersion,nodeImage:agentPoolProfiles[0].nodeImageVersion}" \
    -o table
done
```

Use this to compare node image versions against the snapshot from step 2.

## 10. Operator controls during a run

Stop a run if you need to prevent Fleet from progressing to later members:

```bash
az fleet updaterun stop \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo
```

Skip a target if you need to bypass part of a rollout:

```bash
az fleet updaterun skip \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-demo \
  --targets Stage:production
```

Notes:

- `stop` prevents Fleet from progressing further, but it does not abort an upgrade already in progress on an individual cluster
- `skip` is useful when you want to intentionally bypass a stage, group, or member target

## 11. Create an auto-upgrade profile that reuses the same strategy

```bash
UPDATE_STRATEGY_ID=$(az resource show \
  --ids "$FLEET_ID/updateStrategies/$STRATEGY" \
  --api-version 2026-02-01-preview \
  --query id -o tsv)

az fleet autoupgradeprofile create \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name node-image-channel \
  --channel NodeImage \
  --node-image-selection Consistent \
  --update-strategy-id "$UPDATE_STRATEGY_ID"
```

What this does:

- creates a recurring auto-upgrade profile named `node-image-channel`
- tells Fleet to react to future node image releases
- reuses the same staged rollout strategy, including the approval gate
- uses `Consistent` node image selection so later stages reuse the image version already exercised earlier in the run

## 12. Generate an on-demand run from the auto-upgrade profile

```bash
GENERATED_RUN=$(az fleet autoupgradeprofile generate-update-run \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --auto-upgrade-profile-name node-image-channel \
  --query name -o tsv)

echo "$GENERATED_RUN"
```

Expected result:

- Fleet creates a new update run resource based on the current AKS-published node image version
- the generated run is not started automatically, which gives you time to inspect it first

Inspect the generated run:

```bash
az fleet updaterun show \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$GENERATED_RUN" \
  -o yaml
```

If you want to execute it after review:

```bash
az fleet updaterun start \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name "$GENERATED_RUN"
```

This is the safest way to demonstrate auto-upgrade profiles in a workshop,
because real release-triggered runs might not appear immediately after profile
creation.

## 13. Choose the right auto-upgrade channel

Useful channels for this repo:

- `NodeImage` for recurring node image patching with the least change risk
- `Stable` for conservative ongoing Kubernetes version upgrades
- `Rapid` for moving to the newest supported AKS minor version faster
- `TargetKubernetesVersion` when you want to pin the fleet to a chosen minor version explicitly

When using `TargetKubernetesVersion`, you must also set
`--target-kubernetes-version` in the format `major.minor`, for example `1.33`.

## 14. Optional expansion: run a full Kubernetes version upgrade

Inspect supported upgrades from one of the member clusters:

```bash
az aks get-upgrades -g "$RG" -n "$STAGING_CLUSTER" -o table
```

Then create and start a full upgrade run:

```bash
TARGET_VERSION=<supported-version>

az fleet updaterun create \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name full-upgrade-demo \
  --upgrade-type Full \
  --kubernetes-version "$TARGET_VERSION" \
  --node-image-selection Consistent \
  --update-strategy-name "$STRATEGY"

az fleet updaterun start \
  --resource-group "$RG" \
  --fleet-name "$FLEET" \
  --name full-upgrade-demo
```

Use `Consistent` if you want later stages to reuse the same chosen node image
versions that were exercised in earlier stages.

## 15. Planned maintenance and real-world behavior

- Fleet update runs honor AKS planned maintenance windows
- a member cluster can remain `Pending` if its maintenance window is not open yet
- a member can also remain `Pending` if the target Kubernetes or node image version is not yet available in that cluster's region
- `Latest` gives fresher node images, while `Consistent` prioritizes using the same validated image version across stages
- auto-upgrade profiles can take days or weeks to trigger from a newly published release, which is why this guide uses `generate-update-run` for hands-on learning
- auto-upgrade does not skip multiple Kubernetes minor versions automatically; fleets should first be brought into a reasonably aligned version range

## Verification targets

- `az resource show --ids "$FLEET_ID/updateStrategies/$STRATEGY" --api-version 2026-02-01-preview -o yaml`
- `az fleet updaterun show ... -o yaml`
- `az fleet updaterun show ... -o table`
- `az aks show ... --query "{name:name,controlPlane:kubernetesVersion,nodeImage:agentPoolProfiles[0].nodeImageVersion}" -o table`
- Azure portal Fleet Manager overview if you want a UI view of run history, pending gates, and member state
