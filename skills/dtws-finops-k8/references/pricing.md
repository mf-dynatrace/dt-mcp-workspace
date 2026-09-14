# Node Pricing Reference

> Cloud provider pricing resources and cost estimation formulas.
> Use when the user asks for indicative pricing or cost estimates.

---

## Asking the User

Always ask before assuming:
1. "Do you have node pricing data, or should I find indicative pricing online?"
2. If online: "Where is the K8s cluster deployed? (AWS/Azure/GCP region, or on-prem provider)"

---

## Cloud Provider Pricing Links

### Azure AKS
- VM pricing (Linux): https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/
- Spot VMs: https://azure.microsoft.com/en-us/pricing/spot-vms/
- Savings Plans: https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0017g/

### AWS EKS
- On-Demand: https://aws.amazon.com/ec2/pricing/on-demand/
- Spot Instances: https://aws.amazon.com/ec2/spot/pricing/
- Savings Plans: https://aws.amazon.com/savingsplans/pricing/

### Google GKE
- Machine Types: https://cloud.google.com/compute/all-pricing
- Spot / Preemptible: https://cloud.google.com/compute/docs/instances/preemptible

### On-Premises
- Do NOT apply cloud list pricing to on-prem nodes.
- Report on-prem capacity separately as capex/opex or "equivalent rehost" cost.
- See `metric-pitfalls.md` §5.

---

## Generic Cost Formula (when exact pricing is unavailable)

```
Pod Cost = (Node Hourly Cost × Pod Resource Requests) / Node Total Capacity
```

**Example:**
- Node: 16 vCPU, 64 GB RAM, $0.50/hour
- Pod: 2 vCPU request, 8 GB request
- Pod Cost: ($0.50 × 2/16) + ($0.50 × 8/64) = $0.0625 + $0.0625 = $0.125/hour

---

## Proportional Shared Cost Allocation

For satellite/shared costs (control-plane, storage, network egress, observability tooling):

```
Workload share = (workload requested resources) / (cluster total requested) × shared cost pool
```

---

## Node SKU Inference

Derive the node SKU from allocatable telemetry rather than assuming a type.
See `metric-pitfalls.md` §4 for the query and reasoning.

Example mapping (Azure Dv5 series after ~6% system reservation):
| Allocatable cores | Allocatable RAM | Inferred SKU |
|---|---|---|
| ~30 cores | ~124 GB | Standard_D32s_v5 (32 vCPU / 128 GB) |
| ~15 cores | ~60 GB | Standard_D16s_v5 (16 vCPU / 64 GB) |

---

## Dynatrace Carbon Impact App

For sustainability/GreenOps angle: the Carbon Impact app in Dynatrace can pair
idle/overprovisioned findings with CO₂ estimates. Verify availability in the tenant before
referencing in a report.
