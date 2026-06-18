# Smartscape Migration Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-migration`

Migrate classic/Gen2 entity-based DQL queries to Smartscape equivalents.

---

## Core Entity Mapping Table

| Classic / Gen2 entity | Smartscape field | Smartscape node type | Notes |
|----------------------|-----------------|---------------------|-------|
| `dt.entity.host` | `dt.smartscape.host` | `HOST` | Standard host mapping |
| `dt.entity.service` | `dt.smartscape.service` | `SERVICE` | Standard service mapping |
| `dt.entity.process_group_instance` | `dt.smartscape.process` | `PROCESS` | Process instance maps directly |
| `dt.entity.container_group_instance` | `dt.smartscape.container` | `CONTAINER` | Container-group instance maps directly |
| `dt.entity.kubernetes_cluster` | `dt.smartscape.k8s_cluster` | `K8S_CLUSTER` | |
| `dt.entity.kubernetes_node` | `dt.smartscape.k8s_node` | `K8S_NODE` | |
| `dt.entity.kubernetes_service` | `dt.smartscape.k8s_service` | `K8S_SERVICE` | |
| `dt.entity.cloud_application_instance` | `dt.smartscape.k8s_pod` | `K8S_POD` | Classic cloud app instance becomes pod |
| `dt.entity.cloud_application_namespace` | `dt.smartscape.k8s_namespace` | `K8S_NAMESPACE` | |
| `dt.entity.application` | `dt.smartscape.frontend` | `FRONTEND` | Frontend application mapping |
| `dt.entity.aws_lambda_function` | `dt.smartscape.aws.lambda_function` | `AWS_LAMBDA_FUNCTION` | |

---

## DQL Constructs to Migrate

| Classic construct | Smartscape replacement | Notes |
|------------------|----------------------|-------|
| `entityName(x)` | `name` or `getNodeName(x)` | Prefer `name` when querying nodes directly |
| `entityAttr(x, "...")` | direct node field or `getNodeField(x, "...")` | Prefer direct fields |
| `classicEntitySelector(...)` | node filters plus `traverse` | Start from the constrained side |
| `dt.entity.*` in signal queries | `dt.smartscape.*` | Applies to `by`, `filter`, `fieldsAdd`, etc. |
| `belongs_to[...]`, `runs[...]` | `traverse` or `references[...]` | `references` only for static edges |
| `affected_entity_ids` | `smartscape.affected_entity.ids` | Use Smartscape event fields |
| `affected_entity_types` | `smartscape.affected_entity.types` | |

---

## Migration Workflow

1. Identify the classic input pattern
2. Identify the involved classic entity types
3. Look up the Smartscape replacement in mapping table
4. Check which classic DQL constructs need migration
5. Rewrite using Smartscape primitives: `smartscapeNodes`, `smartscapeEdges`, `traverse`, `references`, `getNodeName()`, `getNodeField()`
6. Check for special cases

---

## Special Cases

- **Host group** — no standalone Smartscape entity; use fields on `HOST`
- **Process group** — no standalone Smartscape entity; use fields on `PROCESS`
- **Container group** — no standalone Smartscape entity
- **Classic IDs** — classic entity IDs do not carry over to Smartscape automatically
