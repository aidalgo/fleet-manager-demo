---
title: Workshop Home
nav_order: 1
description: Azure Kubernetes Fleet Manager workshop hub showing how Fleet fits GitOps delivery, multi-cluster governance, and fleet-wide AKS operations.
permalink: /
---

<!-- markdownlint-disable MD033 -->

<div class="site-hero">
  <p class="site-eyebrow">Azure Kubernetes Fleet Manager Workshop</p>
  <h1>Fleet Manager for GitOps delivery and fleet-wide operations</h1>
  <p class="site-hero-copy">
    Provision the shared environment, run staged AKS updates, explore
    placement and governance scenarios, and finish with a GitOps rollout that
    combines Argo CD with Azure Kubernetes Fleet Manager.
  </p>
  <div class="site-sequence" aria-label="Recommended workshop sequence">
    <span class="site-sequence-step">01 Setup</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">02 Bootstrap</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">03 Updates</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">04-06 Fleet Scenarios</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">07 Argo</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">08 Cleanup</span>
  </div>
  <div class="site-hero-actions">
    <a class="btn btn-primary" href="{{ '/setup/infrastructure/' | relative_url }}">Start the setup track</a>
    <a class="btn" href="{{ '/operations/update-orchestration/' | relative_url }}">Open the first scenario</a>
  </div>
</div>

## Start Here

<p class="site-section-intro">Run these in order before you branch into the focused Fleet scenarios.</p>

<div class="site-card-grid">
  <a class="site-card" href="{{ '/setup/infrastructure/' | relative_url }}">
    <span class="site-card-kicker">Step 01 · Setup</span>
    <strong>Infrastructure setup</strong>
    <span>Provision the resource group, Fleet hub, member clusters, and the staged update strategy.</span>
  </a>
  <a class="site-card" href="{{ '/setup/hub-bootstrap/' | relative_url }}">
    <span class="site-card-kicker">Step 02 · Setup</span>
    <strong>Hub bootstrap</strong>
    <span>Get kubeconfigs, Fleet RBAC, and member labels ready before running a workshop track.</span>
  </a>
  <a class="site-card" href="{{ '/cleanup/' | relative_url }}">
    <span class="site-card-kicker">Step 08 · Finish</span>
    <strong>Cleanup</strong>
    <span>Reset scenario resources and destroy the shared infrastructure when the workshop is complete.</span>
  </a>
</div>

## Workshop Tracks

<p class="site-section-intro">After steps 01 and 02, continue to step 03 for staged AKS updates. Then run steps 04 through 06 for placement and governance scenarios. Finish with step 07 for the GitOps rollout with Argo CD.</p>

<div class="site-card-grid site-card-grid--wide">
  <a class="site-card" href="{{ '/operations/update-orchestration/' | relative_url }}">
    <span class="site-card-kicker">Step 03 · Fleet operations</span>
    <strong>AKS update orchestration</strong>
    <span>Run staged updates, approval gates, and auto-upgrade profiles across the fleet.</span>
  </a>
  <a class="site-card" href="{{ '/scenarios/namespace-governance/' | relative_url }}">
    <span class="site-card-kicker">Step 04 · GitOps governance</span>
    <strong>Namespace placement and governance</strong>
    <span>Establish a namespace boundary everywhere, push a governance baseline to all clusters, and send app config only to selected targets.</span>
  </a>
  <a class="site-card" href="{{ '/scenarios/intelligent-placement/' | relative_url }}">
    <span class="site-card-kicker">Step 05 · Scheduling</span>
    <strong>Intelligent placement</strong>
    <span>Use PickN, preferred selectors, and property sorters to explain why Fleet chose one cluster over another.</span>
  </a>
  <a class="site-card" href="{{ '/scenarios/managed-fleet-namespaces/' | relative_url }}">
    <span class="site-card-kicker">Step 06 · Azure-managed governance</span>
    <strong>Managed Fleet Namespaces</strong>
    <span>Walk through the Azure control-plane model for multi-cluster namespace governance and scoped credentials.</span>
  </a>
  <a class="site-card" href="{{ '/reference/baseline-app-rollout/' | relative_url }}">
    <span class="site-card-kicker">Step 07 · GitOps rollout</span>
    <strong>Baseline Argo app rollout</strong>
    <span>Run the GitOps rollout where Argo CD reconciles the application and Fleet controls cross-cluster placement and promotion.</span>
  </a>
</div>

## What Gets Deployed

<div class="site-pills">
  <span class="site-pill">1 resource group</span>
  <span class="site-pill">1 Fleet hub</span>
  <span class="site-pill">3 AKS member clusters</span>
  <span class="site-pill">Built-in staging, canary, and production groups</span>
  <span class="site-pill">1 reusable Fleet update strategy</span>
</div>

## Recommended Flow

1. Run 01 and 02 to provision the shared environment and prepare Fleet hub access.
2. Run 03 for staged AKS updates, approval gates, and reusable update strategies.
3. Run one or more of 04, 05, or 06 for namespace governance, intelligent placement, or managed fleet namespaces.
4. Run 07 for the GitOps rollout with Argo CD and Fleet.
5. Finish with 08 to clean up the environment.

## Important Details

- Step 03 works directly against the AKS member clusters and does not require Argo CD.
- Steps 04 and 05 use hub-side placement policies to distribute namespaces, governance resources, and workloads across the fleet.
- Step 06 uses Managed Fleet Namespaces, which is currently a preview Azure feature.
- Step 07 adds Argo CD and uses the same staging, canary, and production model for application rollout.
- DNS-based load balancing is intentionally deferred for a later expansion.

<!-- markdownlint-enable MD033 -->