# Custom Instructions

> **This file is gitignored** — your customizations survive git pulls and repo updates.
> Edit this file to add tenant-specific instructions that extend the base configuration.
> The AI agent reads this file at session start and treats its contents as additional
> instructions that **take precedence** over defaults for the same topic.

---

## Business Context

<!-- Describe your organization, industry, and key services -->
<!-- Example:
- **Company:** Acme Corp
- **Industry:** E-commerce / Retail
- **Key Services:** checkout-service, payment-gateway, inventory-api
- **Business Hours:** Mon-Fri 08:00-18:00 AEST
- **Peak Traffic:** Fridays 12:00-14:00, Sale events
-->

## Query Preferences

<!-- Override default query behavior -->
<!-- Example:
- Default timeframe: 3d (instead of 24h)
- Always filter to cluster: "production-au-east"
- Preferred aggregation: p95 (instead of avg)
- Max budget per query: 5 GB
-->

## Entity Focus

<!-- Entities to always include or exclude -->
<!-- Example:
- **Primary services:** SERVICE-ABC123, SERVICE-DEF456
- **Ignore hosts:** HOST-LEGACY01, HOST-TEST02
- **RUM application:** APPLICATION-XYZ789 ("Acme Web Store")
- **Kubernetes cluster:** KUBERNETES_CLUSTER-K8S001
-->

## Report & Output Preferences

<!-- How reports and answers should be formatted -->
<!-- Example:
- Language: Australian English
- Currency: AUD
- Timezone: Australia/Sydney (AEST/AEDT)
- Verbosity: concise (bullet points over paragraphs)
- Always include cost-per-query in reports
-->

## Exclusions & Overrides

<!-- Things to skip or handle differently -->
<!-- Example:
- FinOps reports: exclude namespace "kube-system" and "monitoring"
- Ignore synthetic monitors in error rate calculations
- Skip hosts tagged "environment:dev" in capacity reports
- When investigating errors, always check the "payment-gateway" service first
-->

## Custom Rules

<!-- Any other tenant-specific rules -->
<!-- Example:
- SLO target for all services: 99.9% availability
- Alert threshold: error rate > 1% over 5 minutes
- Always correlate frontend errors with backend spans
- When creating dashboards, use company brand colour #1E3A5F
-->
