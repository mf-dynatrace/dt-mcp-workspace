# Infrastructure Hosts Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-hosts`

Monitor host and process infrastructure: CPU, memory, disk, network, and technology inventory.

---

## Entity Types
- **HOST** — Physical or virtual machines
- **PROCESS** — Running processes and process groups
- **CONTAINER** — Kubernetes containers
- **NETWORK_INTERFACE** — Host network interfaces
- **DISK** — Host disk volumes

## Key Metrics

| Category | Key Metrics |
|----------|-------------|
| Host CPU | `dt.host.cpu.usage`, `dt.host.cpu.user`, `dt.host.cpu.system`, `dt.host.cpu.iowait` (Linux only) |
| Host Memory | `dt.host.memory.usage`, `dt.host.memory.used`, `dt.host.memory.avail.percent` |
| Host Disk | `dt.host.disk.used.percent`, `dt.host.disk.latency` |
| Host Network | `dt.host.net.bytes_rx`, `dt.host.net.bytes_tx` |
| Process CPU | `dt.process.cpu.usage` |
| Process Memory | `dt.process.memory.usage` |
| Process I/O | `dt.process.io.*` |
| Process Network | `dt.process.network.*` |

## Alert Thresholds
- **CPU/Memory/Disk:** 80% warning, 90% critical
- **Network:** >70% high, >85% saturated
- **Disk Latency:** >20ms bottleneck
- **Swap:** >30% warning, >50% critical

---

## Key Workflows

### Host Discovery
```dql
smartscapeNodes "HOST"
| fieldsAdd os.type, cloud.provider, host.logical.cpu.cores, host.physical.memory
| summarize host_count = count(), by: {os.type, cloud.provider}
```

### Resource Utilization
```dql
timeseries {
  cpu = avg(dt.host.cpu.usage),
  memory = avg(dt.host.memory.usage),
  disk = avg(dt.host.disk.used.percent)
}, by: {dt.smartscape.host}
| fieldsAdd host_name = getNodeName(dt.smartscape.host)
| filter arrayAvg(cpu) > 80 or arrayAvg(memory) > 80
```

### Technology Stack Inventory
```dql
smartscapeNodes "PROCESS"
| fieldsAdd process.software_technologies
| expand tech = process.software_technologies
| fieldsAdd tech_type = tech[type], tech_version = tech[version]
| summarize process_count = count(), by: {tech_type, tech_version}
| sort process_count desc
```

### Service Discovery via Ports
```dql
smartscapeNodes "PROCESS"
| fieldsAdd process.listen_ports, dt.process_group.detected_name
| filter isNotNull(process.listen_ports) and arraySize(process.listen_ports) > 0
| expand port = process.listen_ports
| summarize process_count = count(), by: {port, dt.process_group.detected_name}
| sort toLong(port) asc | limit 50
```

---

## Cloud-Specific Attributes

| Cloud | Key Fields |
|-------|-----------|
| **AWS** | `cloud.provider == "aws"`, `aws.region`, `aws.availability_zone`, `aws.account.id`, `aws.resource.id` |
| **Azure** | `cloud.provider == "azure"`, `azure.location`, `azure.subscription`, `azure.resource.group` |
| **Kubernetes** | `k8s.cluster.name`, `k8s.namespace.name`, `k8s.node.name`, `k8s.pod.name` |

## Tags and Metadata
- Generic `tags` field is NOT populated in smartscape queries — use specific tag fields
- Azure Tags: `tags:azure[dt_owner_team]`
- Custom Metadata: `host.custom.metadata[*]`
- Cost: `dt.cost.costcenter`, `dt.cost.product`
