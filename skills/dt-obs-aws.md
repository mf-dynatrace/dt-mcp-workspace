# AWS Cloud Infrastructure Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-obs-aws`

Monitor and analyze AWS resources using Dynatrace Smartscape and DQL.

---

## Entity Types

| Category | Entity Types |
|----------|-------------|
| **Compute** | `AWS_EC2_INSTANCE`, `AWS_LAMBDA_FUNCTION`, `AWS_ECS_CLUSTER`, `AWS_ECS_SERVICE`, `AWS_EKS_CLUSTER` |
| **Networking** | `AWS_EC2_VPC`, `AWS_EC2_SUBNET`, `AWS_EC2_SECURITYGROUP`, `AWS_EC2_NATGATEWAY` |
| **Database** | `AWS_RDS_DBINSTANCE`, `AWS_RDS_DBCLUSTER`, `AWS_DYNAMODB_TABLE`, `AWS_ELASTICACHE_CACHECLUSTER` |
| **Storage** | `AWS_S3_BUCKET`, `AWS_EC2_VOLUME`, `AWS_EFS_FILESYSTEM` |
| **Load Balancing** | `AWS_ELASTICLOADBALANCINGV2_LOADBALANCER`, `AWS_ELASTICLOADBALANCINGV2_TARGETGROUP` |
| **Messaging** | `AWS_SQS_QUEUE`, `AWS_SNS_TOPIC`, `AWS_EVENTS_EVENTBUS`, `AWS_MSK_CLUSTER` |

## Common Fields
- `aws.account.id`, `aws.region`, `aws.resource.id`, `aws.resource.name`, `aws.arn`
- `aws.vpc.id`, `aws.subnet.id`, `aws.availability_zone`, `aws.security_group.id` (array)
- `tags` — use `tags[TagName]`

---

## AWS Metric Naming Convention

Pattern: `cloud.aws.<service>.<MetricName>.By.<DimensionName>`

| CloudWatch Metric | Dynatrace Metric Key |
|-------------------|---------------------|
| EC2 CPUUtilization | `cloud.aws.ec2.CPUUtilization.By.InstanceId` |
| EC2 NetworkIn | `cloud.aws.ec2.NetworkIn.By.InstanceId` |
| RDS CPUUtilization | `cloud.aws.rds.CPUUtilization.By.DBInstanceIdentifier` |
| Lambda Invocations | `cloud.aws.lambda.Invocations.By.FunctionName` |
| SQS Messages | `cloud.aws.sqs.ApproximateNumberOfMessagesVisible.By.QueueName` |
| ELB RequestCount | `cloud.aws.elasticloadbalancingv2.RequestCount.By.LoadBalancer` |

```dql
timeseries cpu = avg(cloud.aws.ec2.CPUUtilization.By.InstanceId),
           by: {dt.smartscape_source.id}, from: now()-1h
```

**Important:** These are **Dynatrace metrics** ingested from AWS — not "CloudWatch metrics."

---

## Core Query Patterns

### Resource Discovery
```dql
smartscapeNodes "AWS_EC2_INSTANCE"
| filter aws.account.id == "<ACCOUNT_ID>" and aws.region == "<REGION>"
| summarize count = count(), by: {type} | sort count desc
```

### Configuration Parsing
```dql
smartscapeNodes "AWS_RDS_DBINSTANCE"
| parse aws.object, "JSON:awsjson"
| fieldsAdd engine = awsjson[configuration][engine]
| summarize db_count = count(), by: {engine, aws.region}
```

### Relationship Traversal

Key traversal pairs:
- **LB → Target Groups:** `traverse "balanced_by", "AWS_ELASTICLOADBALANCINGV2_TARGETGROUP", direction:backward`
- **Target Group → Instances:** `traverse "balances", "AWS_EC2_INSTANCE"`
- **Instance → SG:** `traverse "uses", "AWS_EC2_SECURITYGROUP"`
- **Instance → HOST:** `traverse "runs_on", "HOST", direction: backward`
- **RDS → Cluster:** `traverse "is_part_of", "AWS_RDS_DBCLUSTER"`
- **Lambda → IAM Role:** `traverse "uses", "AWS_IAM_ROLE"`

### Tag-Based Ownership
```dql
smartscapeNodes "AWS_*"
| filter isNotNull(tags[CostCenter])
| summarize resource_count = count(), by: {tags[CostCenter], type}
| sort resource_count desc
```

---

## Relationship Types
- `is_attached_to` — Exclusive attachment (volume to instance)
- `uses` — Dependency (instance uses security group)
- `runs_on` — Vertical (instance runs on AZ)
- `is_part_of` — Composition (instance in cluster)
- `belongs_to` — Aggregation (service belongs to cluster)
- `balances` / `balanced_by` — Load balancing
