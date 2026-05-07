# Azure AKS Fleet Manager GitOps Demo

This repository scaffolds an Argo-first Azure Kubernetes Fleet Manager demo.
Argo CD remains the GitOps delivery engine for workload manifests staged on the
Fleet hub. Fleet adds multi-cluster placement, promotion, governance, and AKS
fleet operations on top of that model.

## Docs site

This repository now includes a GitHub Pages site built with Jekyll and Just the
Docs theme. The landing page lives in `index.md`, and the workshop guides under
`docs/` remain the source of truth for the published content.

For a local preview:

```bash
bundle install --path vendor/bundle
BUNDLE_PATH=vendor/bundle bundle exec jekyll serve
```

Then open `http://127.0.0.1:4000/fleet-manager-demo/`.

If the repository name changes, update `baseurl` in `_config.yml` before
publishing.

## Current focus

| Guide | Capability | Status | Argo role | Notes |
| --- | --- | --- | --- | --- |
| `docs/01-infrastructure-setup.md` | Shared infrastructure setup | Available | None | Applies to every scenario |
| `docs/02-hub-bootstrap.md` | Shared hub bootstrap | Available | Optional | Shared kubeconfig and Fleet label checks |
| `docs/03-baseline-app-rollout.md` | Baseline Argo staged rollout | Available | Required | Reference pattern for app delivery |
| `docs/04-namespace-placement.md` | GitOps namespace governance plus `ResourcePlacement` | Available | Optional | Namespace and governance pack on all clusters, app config only on staging and canary |
| `docs/05-intelligent-placement.md` | Intelligent placement | Available | Optional | `PickN` with weighted preference for `canary` and `production` |
| `docs/06-managed-fleet-namespaces.md` | Managed Fleet Namespaces | Available (Preview) | Complementary | Scripted Fleet managed-namespace lifecycle |
| `docs/07-update-orchestration.md` | AKS update orchestration | Available | Not required | Staged node-image updates with approval gate and auto-upgrade profile walkthrough |
| Deferred | DNS load balancing | Deferred | Complementary | Intentionally held for a later pass |

## What gets deployed

- 1 Azure resource group.
- 1 hubful Azure Kubernetes Fleet Manager resource.
- 3 AKS member clusters in one region: `staging`, `canary`, and `production`.
- 1 Azure Fleet update strategy for staged AKS upgrades.

Terraform uses `azurerm` for AKS and `azapi` for Fleet-specific resources so
the Fleet hub can be created directly from Terraform.

## Documentation flow

Shared setup:

- `docs/01-infrastructure-setup.md`
- `docs/02-hub-bootstrap.md`

Scenario guides:

- `docs/03-baseline-app-rollout.md`
- `docs/04-namespace-placement.md`
- `docs/05-intelligent-placement.md`
- `docs/06-managed-fleet-namespaces.md`
- `docs/07-update-orchestration.md`

Cleanup:

- `docs/08-cleanup.md`

The baseline rollout guide remains the current reference implementation for Argo
plus Fleet delivery. The namespace placement and intelligent placement guides
now include concrete Fleet manifest sets that are also Argo-sync friendly via
their `kustomization.yaml` files. The managed namespaces guide now includes a
concrete Fleet CLI workflow, and the update orchestration guide remains the
separate fleet-operations track.

## Repository layout

- `infra/`: Terraform for Azure resources.
- `k8s/argocd/`: Hub-staged Argo CD `Application`.
- `k8s/fleet/`: Fleet placement and staged app rollout manifests, including dedicated use-case folders.
- `scripts/`: Helper scripts for kubeconfig, Argo CD bootstrap, Fleet label verification, rollout apply, and use-case lifecycle helpers.
- `docs/`: Shared setup, scenario guides, and cleanup.

## Prerequisites

- Terraform `>= 1.6`
- Azure CLI `>= 2.82.0`
- `kubectl`
- Access to create AKS and Fleet resources in the target subscription
- The Azure CLI `fleet` extension
- The `Azure Kubernetes Fleet Manager RBAC Cluster Admin` role on the Fleet resource before using the hub kubeconfig

## Quick start

For the current Argo delivery reference flow:

1. Follow `docs/01-infrastructure-setup.md`.
1. Follow `docs/02-hub-bootstrap.md`.
1. Run `scripts/bootstrap-argocd.sh`.
1. Follow `docs/03-baseline-app-rollout.md`.

For AKS fleet operations:

1. Follow `docs/01-infrastructure-setup.md`.
1. Follow `docs/02-hub-bootstrap.md`.
1. Follow `docs/07-update-orchestration.md`.

For the newly added scenario helpers:

- `./scripts/apply-namespace-placement.sh apply|delete`
- `./scripts/apply-intelligent-placement.sh apply|delete`
- `./scripts/apply-managed-fleet-namespaces.sh create|show|hub-credentials|member-credentials|delete`

## Deferred follow-up

DNS-based load balancing remains intentionally deferred. It still fits the
Argo-first model, but it adds preview networking and Azure Traffic Manager
complexity. When it is added later, it should land as its own scenario guide
instead of being mixed into the current rollout, governance, or update tracks.
