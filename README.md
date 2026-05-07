# Azure AKS Fleet Manager GitOps Demo

This repository shows how Azure Kubernetes Fleet Manager works as a
multi-cluster control plane for both GitOps delivery and fleet-wide AKS
operations.

The reference application flow uses Argo CD as the GitOps engine. Azure
Kubernetes Fleet Manager handles the multi-cluster concerns around that flow:
placement, staged promotion, governance, and update orchestration across
`staging`, `canary`, and `production` clusters.

The workshop now starts with Fleet-native operations so you can explain Fleet
directly, then moves through focused placement and governance scenarios, and
closes with the Argo CD example as the most advanced GitOps story in the repo.

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

## What this repo demonstrates

This workshop is organized to show two complementary ideas:

- how Fleet Manager solves multi-cluster rollout, targeting, governance, and day-2 operations
- how those same Fleet capabilities can sit underneath a GitOps workflow, with Argo CD as one practical reconciler

| Guide | Capability | Status | Argo role | Notes |
| --- | --- | --- | --- | --- |
| `docs/01-infrastructure-setup.md` | Shared infrastructure setup | Available | None | Applies to every scenario |
| `docs/02-hub-bootstrap.md` | Shared hub bootstrap | Available | Optional | Shared kubeconfig and Fleet label checks |
| `docs/03-update-orchestration.md` | AKS update orchestration | Available | Not required | Recommended opening scenario for the workshop story |
| `docs/04-namespace-placement.md` | GitOps namespace governance plus `ResourcePlacement` | Available | Optional | Namespace and governance pack on all clusters, app config only on staging and canary |
| `docs/05-intelligent-placement.md` | Intelligent placement | Available | Optional | `PickN` with weighted preference for `canary` and `production` |
| `docs/06-managed-fleet-namespaces.md` | Managed Fleet Namespaces | Available (Preview) | Complementary | Scripted Fleet managed-namespace lifecycle |
| `docs/07-baseline-app-rollout.md` | Baseline Argo staged rollout | Available | Required | Advanced GitOps closing example where Argo reconciles the app and Fleet controls promotion |
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

- `docs/03-update-orchestration.md`
- `docs/04-namespace-placement.md`
- `docs/05-intelligent-placement.md`
- `docs/06-managed-fleet-namespaces.md`
- `docs/07-baseline-app-rollout.md`

Cleanup:

- `docs/08-cleanup.md`

The update orchestration guide is now the first scenario because it shows Fleet
in its most direct operating model. The namespace placement and intelligent
placement guides then isolate Fleet targeting behaviors, the managed namespaces
guide covers the Azure-managed governance path, and the baseline rollout guide
closes the workshop with the full Argo-plus-Fleet GitOps story.

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

For the recommended Fleet-first workshop flow:

1. Follow `docs/01-infrastructure-setup.md`.
1. Follow `docs/02-hub-bootstrap.md`.
1. Follow `docs/03-update-orchestration.md`.
1. Follow one or more of `docs/04-namespace-placement.md`, `docs/05-intelligent-placement.md`, or `docs/06-managed-fleet-namespaces.md`.
1. Run `scripts/bootstrap-argocd.sh`.
1. Follow `docs/07-baseline-app-rollout.md`.
1. Follow `docs/08-cleanup.md`.

For the newly added scenario helpers:

- `./scripts/apply-namespace-placement.sh apply|delete`
- `./scripts/apply-intelligent-placement.sh apply|delete`
- `./scripts/apply-managed-fleet-namespaces.sh create|show|hub-credentials|member-credentials|delete`

## Deferred follow-up

DNS-based load balancing remains intentionally deferred. It still fits the
repo's GitOps-plus-Fleet model, but it adds preview networking and Azure
Traffic Manager complexity. When it is added later, it should land as its own
scenario guide instead of being mixed into the current rollout, governance, or
update tracks.
