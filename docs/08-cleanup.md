---
title: 08. Cleanup
nav_order: 80
description: Tear down scenario resources and shared infrastructure after the workshop.
permalink: /cleanup/
---

Use this guide when you are finished with the workshop and want to return to a
clean state.

## 1. Reset the scenario resources you actually used

Start by removing the scenario-specific resources before you destroy the shared
infrastructure. Choose only the cleanup commands that match the scenarios you
ran.

- If you ran `docs/07-baseline-app-rollout.md`, reset the propagated guestbook resources before destroying the infrastructure:

```bash
bash scripts/clear-app-rollout.sh
```

- If you ran the additional scenario helpers, reset them before destroying the infrastructure:

```bash
./scripts/apply-namespace-placement.sh delete
./scripts/apply-intelligent-placement.sh delete
./scripts/apply-managed-fleet-namespaces.sh delete
```

Expected result:

- the guestbook app rollout is cleared if you ran the baseline track
- the namespace-governance, intelligent-placement, or managed-namespace assets are removed if you ran those tracks
- the hub is no longer carrying leftover scenario state into the next demo run

If you are not sure whether a scenario is still active, it is safer to run the
matching reset command now than to discover leftover objects after the next
deployment.

## 2. Destroy the shared infrastructure

```bash
cd infra
terraform destroy
```

Expected result:

- Terraform removes the resource group, Fleet resource, AKS member clusters, and related shared infrastructure

## 3. Remove the local demo kubeconfig

```bash
rm -f ../.kube/fleet-demo.yaml
```

This prevents the next workshop run from accidentally reusing stale contexts.

## 4. If Azure leaves Fleet-managed resources behind

In some cases Azure creates Fleet-managed resources that take longer to
disappear than the main resource group. Re-run `terraform destroy` after the
Fleet resource is gone, or remove any leftover Fleet-managed resource groups
from the Azure portal once the main deployment is deleted.

Treat this as the final teardown checkpoint. The workshop is fully cleaned up
only when the Azure resource group is gone and the local kubeconfig file has
been removed.
