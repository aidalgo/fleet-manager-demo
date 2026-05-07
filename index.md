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
    This workshop shows where Azure Kubernetes Fleet Manager fits in a real
    operating model: Argo CD is the GitOps reconciler in the reference flow,
    while Fleet handles multi-cluster placement, staged promotion, governance,
    and AKS update orchestration.
  </p>
  <div class="site-sequence" aria-label="Recommended workshop sequence">
    <span class="site-sequence-step">01 Setup</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">02 Bootstrap</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">03 Baseline</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">Choose 04-07</span>
    <span class="site-sequence-arrow">&rarr;</span>
    <span class="site-sequence-step">08 Cleanup</span>
  </div>
  <div class="site-hero-actions">
    <a class="btn btn-primary" href="{{ '/setup/infrastructure/' | relative_url }}">Start the setup track</a>
    <a class="btn" href="{{ '/reference/baseline-app-rollout/' | relative_url }}">Open the baseline scenario</a>
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

<p class="site-section-intro">After steps 01 and 02, run step 03 once to establish the GitOps reference pattern, then choose one or more of steps 04 through 07 to focus on specific Fleet capabilities.</p>

<div class="site-card-grid site-card-grid--wide">
  <a class="site-card" href="{{ '/reference/baseline-app-rollout/' | relative_url }}">
    <span class="site-card-kicker">Step 03 · Reference</span>
    <strong>Baseline Argo app rollout</strong>
    <span>Start with the reference GitOps flow where Argo reconciles the app and Fleet controls cross-cluster rollout and promotion.</span>
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
  <a class="site-card" href="{{ '/operations/update-orchestration/' | relative_url }}">
    <span class="site-card-kicker">Step 07 · Day-2 operations</span>
    <strong>AKS update orchestration</strong>
    <span>Run staged updates with approval gates, then extend the same strategy into recurring auto-upgrade profiles.</span>
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
2. Run 03 once so everyone sees the baseline Argo-plus-Fleet delivery pattern.
3. Choose one or more of 04, 05, 06, or 07 depending on whether you want to demo governance, scheduling, managed namespaces, or fleet operations.
4. Finish with 08 to clean up the environment.

## Workshop Notes

- The baseline scenario is the clearest example of how Fleet complements a GitOps tool instead of replacing it.
- The placement and governance scenarios are optimized for an Argo-friendly GitOps model.
- Managed Fleet Namespaces remain a preview Azure control-plane feature.
- The update orchestration track is the strongest day-2 operations story in the repo.
- DNS-based load balancing is intentionally deferred for a later expansion.

<!-- markdownlint-enable MD033 -->