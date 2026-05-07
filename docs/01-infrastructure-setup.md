---
title: 01. Infrastructure Setup
nav_order: 10
description: Provision the shared Azure Fleet Manager workshop infrastructure.
permalink: /setup/infrastructure/
---

This is the shared starting point for every scenario in this repository.

## Purpose

Provision the Azure resources reused across the baseline rollout and the focused
Fleet use cases:

- 1 resource group
- 1 Fleet hub
- 3 AKS member clusters grouped as `staging`, `canary`, and `production`
- 1 Fleet update strategy for staged AKS upgrades

## Prerequisites

- Terraform is installed.
- Azure CLI is installed and logged in.
- Your Azure principal can create AKS and Fleet resources.

## Configure Terraform inputs

The minimum required input is the subscription ID.

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set `subscription_id`.

If you want a richer AKS update story, set `kubernetes_version` to a supported
non-latest version in the target region before applying Terraform.

## Apply Terraform

```bash
cd infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Check that the environment is ready for the workshop

```bash
terraform output
```

Before you continue, confirm that Terraform returns the values the rest of the
workshop depends on.

The most important outputs are:

- `resource_group_name`
- `fleet_name`
- `fleet_id`
- `fleet_update_strategy_name`
- `staging_cluster_name`
- `canary_cluster_name`
- `production_cluster_name`

Expected result:

- Terraform returns the Fleet hub name and ID
- Terraform returns all three member-cluster names
- Terraform returns the staged AKS update strategy name

If one of those values is missing, stop here and fix the infrastructure apply
before moving on. The next guides assume the shared environment already exists.

## Choose your next guide

- Continue to `docs/02-hub-bootstrap.md` next. That page prepares hub access,
  kubeconfigs, and member-cluster checks for every workshop track.
- After `docs/02-hub-bootstrap.md`, start with
  `docs/03-update-orchestration.md` if you want the recommended Fleet-first
  workshop flow.
- After `docs/02-hub-bootstrap.md`, use `docs/04-namespace-placement.md` or
  `docs/05-intelligent-placement.md` if you want a Fleet placement workshop.
- After `docs/02-hub-bootstrap.md`, use
  `docs/06-managed-fleet-namespaces.md` if you want the Azure-managed
  namespace-governance path.
- After `docs/02-hub-bootstrap.md`, use
  `docs/07-baseline-app-rollout.md` if you want to close with the advanced
  Argo-plus-Fleet delivery example.

## Notes

- The member AKS clusters are intentionally small so the demo stays inexpensive.
- The Fleet hub is created through `azapi`, not `azurerm`, because hub support needs the ARM surface directly.
