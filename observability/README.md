# Observability

Local-first observability stack for the `tutorials` kind cluster.

It deploys:

- VictoriaMetrics Single for metrics
- VictoriaLogs Single for logs
- VictoriaTraces Single for traces
- Grafana for a combined UI
- OpenTelemetry Collector Contrib as the ingestion/fan-out point
- Linkerd telemetry collector for Linkerd metrics and logs
- Traefik as a local-only UI proxy

The stack uses upstream Helm charts, disables PVCs, and defaults retention to `30d`. Treat in-cluster storage as ephemeral and bounded.

## Quick start

```bash
just observability/deploy
just observability/smoke
just observability/ui
```

Then open:

| UI | URL |
|----|-----|
| Home | <http://localhost:8080> |
| Grafana | <http://localhost:3000> |
| Metrics | <http://localhost:8428/vmui> |
| Logs | <http://localhost:9428/select/vmui> |
| Traces | <http://localhost:10428> |

Override local retention:

```bash
OBSERVABILITY_RETENTION=7d just observability/deploy
```

Print access hints any time:

```bash
just observability/urls
```

## Storage and EKS Auto Mode

| Environment | Recommended shape |
|-------------|-------------------|
| Local kind | Keep PVCs disabled. Use Victoria* as a disposable hot cache. Add S3 fan-out only when you need a raw archive. |
| EKS Auto Mode | Keep the `amazon-cloudwatch-observability` add-on as the durable AWS diagnostics plane. Use Victoria*/Grafana only as an in-cluster hot UI. |
| Production self-hosted Victoria | Use upstream cluster/HA charts, explicit EBS-backed `StorageClass`, zone spread, PodDisruptionBudgets, and retention sized by time and disk. |

Do not rely on an implicit default `StorageClass` for this local stack. Do not make HA Victoria the kind default; it adds pods, volumes, scheduling constraints, and failure modes that distract from the lab.

EKS Auto example:

```bash
just observability/deploy-eksauto-cloudwatch
```

That deploys ephemeral Victoria*/Grafana in cluster and configures the app OpenTelemetry collector to send metrics to CloudWatch Metrics, logs to CloudWatch Logs, and traces to X-Ray.

## Access model

Services are `ClusterIP` only. No Ingress, LoadBalancer, DNS, or TLS certificates are created.

Humans use one temporary port-forward to a meshed Traefik proxy:

```bash
just observability/ui
```

The proxy gets the `observability-ui` Linkerd identity. Linkerd policy allows that identity to query Grafana and the Victoria backends. Direct backend service URLs still exist for collectors and debugging, but policy restricts them to approved mesh identities.

## Linkerd policy model

Deploy annotates the `observability` namespace with:

```bash
linkerd.io/inject=enabled
config.linkerd.io/default-inbound-policy=deny
```

Allowed paths:

| Source | Destination | Purpose |
|--------|-------------|---------|
| Meshed apps | OTel collector ports `4317`/`4318` | Send OTLP telemetry |
| OTel collector | Victoria backends | Write app metrics, logs, traces |
| Linkerd telemetry collector | Victoria backends | Write Linkerd metrics and logs |
| Local browser via `kubectl port-forward` | `observability-ui` | Temporary UI access |
| `observability-ui` | Grafana and Victoria backends | UI/API access through the documented path |
| Grafana | Victoria backends | Query provisioned datasources |

For intentionally non-meshed senders, add a narrow `ServerAuthorization` instead of exposing the collector through ingress.

## Send data

In-cluster workloads can send OTLP to:

| Protocol | Endpoint |
|----------|----------|
| OTLP gRPC | `otel-collector.observability.svc.cluster.local:4317` |
| OTLP HTTP | `http://otel-collector.observability.svc.cluster.local:4318` |

The collector forwards:

- metrics to `victoria-metrics-single-server:8428/opentelemetry/v1/metrics`
- logs to `victoria-logs-single-server:9428/insert/opentelemetry/v1/logs`
- traces to `victoria-traces-single-server:10428/insert/opentelemetry/v1/traces`

## Linkerd telemetry

The `linkerd-telemetry-collector` DaemonSet:

- scrapes Linkerd proxy and control-plane admin ports with the collector's Prometheus receiver
- tails Linkerd control-plane logs and injected `linkerd-proxy` sidecar logs from node container logs
- writes Linkerd metrics to VictoriaMetrics
- writes Linkerd logs to VictoriaLogs

Smoke verification checks that VictoriaMetrics has `up{job="linkerd-control-plane"}` samples:

```bash
just observability/smoke
```

## Optional S3 fan-out

Enable collector fan-out to S3 when you want raw telemetry outside disposable cluster storage:

```bash
OBSERVABILITY_S3_BUCKET=my-observability-archive \
OBSERVABILITY_S3_REGION="${AWS_REGION:-$(aws configure get region)}" \
OBSERVABILITY_S3_BASE_PREFIX=local-kind \
just observability/deploy-s3
```

Objects are OTLP JSON, gzip-compressed, and partitioned like:

```text
s3://$OBSERVABILITY_S3_BUCKET/$OBSERVABILITY_S3_BASE_PREFIX/{metrics,logs,traces}/year=YYYY/month=MM/day=DD/hour=HH/...
```

Credentials are not stored in Git. For local kind, export AWS environment variables or create a Kubernetes Secret and add `extraEnvs` in `charts/observability/opentelemetry-collector-values.yaml`. In cloud, prefer Pod Identity or IRSA.

## Iceberg / DuckLake shape

Keep ingestion simple:

```text
apps -> OpenTelemetry Collector -> Victoria* hot store (30d, ephemeral)
                              \-> S3 raw OTLP archive
```

Run a separate offline job to compact/convert S3 OTLP JSON into Apache Iceberg or DuckLake tables. That job can evolve independently and does not risk telemetry ingestion.

Suggested table layout:

- database/schema: `observability`
- tables: `metrics_otlp`, `logs_otlp`, `traces_otlp`
- partitions: `signal`, `date`, `hour`, optionally `service.name`
- source path: `s3://bucket/base/{metrics,logs,traces}/year=*/month=*/day=*/hour=*`

## What to study

| Path | Purpose |
|------|---------|
| `justfile` | Deploy, smoke, UI, and S3/EKS variants |
| `ui-proxy.yaml` | Local Traefik UI proxy |
| `linkerd-policy.yaml` | Mesh authorization policy |
| `../charts/observability/*values.yaml` | Upstream Helm chart values and collector overlays |

## Cleanup

```bash
just observability/clean
```

## References

- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Grafana documentation](https://grafana.com/docs/)
- [VictoriaMetrics documentation](https://docs.victoriametrics.com/)
- [VictoriaLogs documentation](https://docs.victoriametrics.com/victorialogs/)
- [Linkerd policy](https://linkerd.io/2/features/policy/)
- [Amazon CloudWatch Observability EKS add-on](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-addon.html)
