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
    Start with Fleet-native operations to understand the core control plane,
    then move through placement and governance scenarios, and finish with an
    advanced Argo CD example where Fleet still controls multi-cluster rollout.
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

<p class="site-section-intro">After steps 01 and 02, start with step 03 to explain Fleet in a native operations flow, move through steps 04 through 06 for focused capabilities, and close with step 07 as the advanced GitOps example.</p>

<div class="site-card-grid site-card-grid--wide">
  <a class="site-card" href="{{ '/operations/update-orchestration/' | relative_url }}">
    <span class="site-card-kicker">Step 03 · Fleet operations</span>
    <strong>AKS update orchestration</strong>
    <span>Start with staged updates, approval gates, and auto-upgrade profiles to explain Fleet in its most direct operating model.</span>
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
    <span class="site-card-kicker">Step 07 · Advanced GitOps</span>
    <strong>Baseline Argo app rollout</strong>
    <span>Finish with the full GitOps flow where Argo reconciles the app and Fleet controls cross-cluster rollout and promotion.</span>
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
2. Run 03 first to explain Fleet through staged AKS updates, approval gates, and reusable strategies.
3. Choose one or more of 04, 05, or 06 depending on whether you want to demo governance, scheduling, or managed namespaces.
4. Finish with 07 to show how those same Fleet concepts apply in an advanced Argo-driven GitOps flow.
5. Finish with 08 to clean up the environment.

## Workshop Notes

- Step 03 is the best opening scenario when you want to explain Fleet without introducing GitOps tooling first.
- The placement and governance scenarios are optimized for an Argo-friendly GitOps model.
- Step 07 is the advanced example that shows Fleet complementing Argo CD instead of replacing it.
- Managed Fleet Namespaces remain a preview Azure control-plane feature.
- DNS-based load balancing is intentionally deferred for a later expansion.

<!-- markdownlint-enable MD033 -->