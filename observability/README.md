# Local Observability

Small local-first observability stack for the `tutorials` kind cluster:

- **VictoriaMetrics Single** for metrics
- **VictoriaLogs Single** for logs
- **VictoriaTraces Single** for traces
- **Grafana** for a combined metrics/logs/traces UI
- **OpenTelemetry Collector Contrib** as one ingestion/fan-out point
- **Linkerd telemetry collector** for Linkerd metrics and logs
- **Traefik** as the local-only UI proxy

The stack uses upstream Helm charts, disables PVCs, and sets local retention to `30d` by default. That keeps all in-cluster storage ephemeral and bounded.

## Storage and EKS Auto Mode

| Environment | Recommended shape |
|-------------|-------------------|
| Local kind | Keep PVCs disabled. Treat Victoria* as a disposable hot cache; use `just observability/deploy-s3` only if you want a raw archive. |
| EKS Auto Mode | Keep the `amazon-cloudwatch-observability` addon as the durable AWS diagnostics plane. If you also deploy Victoria*/Grafana, use it as the in-cluster day-to-day UI and fan out app OTLP to CloudWatch Metrics, CloudWatch Logs, and X-Ray/ServiceLens. |
| Production self-hosted Victoria | Use upstream Victoria cluster/HA charts with explicit EBS-backed `StorageClass`, zone spread, PodDisruptionBudgets, and retention sized by both time and disk. |

Do not rely on an implicit cluster default `StorageClass` for this local stack, and do not make HA Victoria the default for kind. HA adds pods, volumes, scheduling constraints, and operational failure modes; keep the default small until Victoria itself is the durable observability system.

EKS Auto example:

```bash
just observability/deploy-eksauto-cloudwatch
```

This deploys the same ephemeral Victoria*/Grafana hot store, but overlays the app OTel collector with AWS exporters. It sends metrics to CloudWatch Metrics via EMF, logs to CloudWatch Logs, and traces to X-Ray while keeping the Victoria datasources available in cluster.

## Deploy

```bash
just observability/deploy
```

Override retention:

```bash
OBSERVABILITY_RETENTION=7d just observability/deploy
```

Services are ClusterIP-only. No ingress is created or required. The namespace is Linkerd-injected with default-deny inbound policy, then `observability/linkerd-policy.yaml` opens only the intended mesh paths.

For a local kind run with verification:

```bash
just observability/deploy
just observability/smoke
just observability/ui
```

## Access UIs

The Victoria* frontends stay internal. Humans use one temporary port-forward to a tiny, meshed Traefik `observability-ui` proxy:

```bash
just observability/ui
```

Then open:

- Home: `http://localhost:8080`
- Grafana: `http://localhost:3000`
- Metrics: `http://localhost:8428/vmui`
- Logs: `http://localhost:9428/select/vmui`
- Traces: `http://localhost:10428`

This proxy is still a `ClusterIP` service. It does not create Ingress, LoadBalancer, DNS, or TLS certificates. Linkerd makes the proxy useful by giving Traefik the `observability-ui` mesh identity, and policy allows that identity to query the Victoria backends.

Grafana is also internal-only. It has ephemeral storage, anonymous local admin access, and pre-provisioned datasources for VictoriaMetrics, VictoriaLogs, and VictoriaTraces. Use it as the combined UI; keep the Victoria-native UIs for direct debugging.

In-cluster services can use the same proxy URLs if they need UI/API access through the documented policy path:

- Home: `http://observability-ui.observability.svc.cluster.local:8080`
- Grafana: `http://observability-ui.observability.svc.cluster.local:3000`
- Metrics: `http://observability-ui.observability.svc.cluster.local:8428/vmui`
- Logs: `http://observability-ui.observability.svc.cluster.local:9428/select/vmui`
- Traces: `http://observability-ui.observability.svc.cluster.local:10428`

Direct backend service URLs still exist for the collector and debugging, but Linkerd policy restricts them to approved mesh identities:

- Metrics backend: `http://victoria-metrics-single-server.observability.svc.cluster.local:8428`
- Logs backend: `http://victoria-logs-single-server.observability.svc.cluster.local:9428`
- Traces backend: `http://victoria-traces-single-server.observability.svc.cluster.local:10428`

You can also print these commands at any time:

```bash
just observability/urls
```

Do not add Ingress just to view this local stack. Port-forwarding keeps the browser access explicit and avoids exposing telemetry frontends by default.

## Linkerd policy model

Deploy creates the `observability` namespace with:

```bash
linkerd.io/inject=enabled
config.linkerd.io/default-inbound-policy=deny
```

That means all meshed pods get sidecars, and inbound traffic is denied unless a Linkerd `Server` plus `ServerAuthorization` allows it.

Allowed paths:

- **Apps -> OTel collector** on OTLP gRPC `4317` and OTLP HTTP `4318`: any authenticated meshed workload can send telemetry.
- **OTel collector -> Victoria backends**: only the `otel-collector` service account can write application metrics, logs, and traces.
- **Linkerd telemetry collector -> Victoria backends**: only the `linkerd-telemetry-collector` service account can write Linkerd metrics and logs.
- **Browser -> observability-ui**: `kubectl port-forward` reaches the ClusterIP-only Traefik UI proxy.
- **observability-ui -> Grafana and Victoria backends**: only the `observability-ui` service account can reach the UI/API ports exposed through the local proxy.
- **Grafana -> Victoria backends**: Grafana uses its provisioned datasources to query metrics, logs, and traces from inside the meshed namespace.

This keeps browser access simple without making the Victoria services public. Linkerd supplies identity and policy; `kubectl port-forward` supplies the temporary local access path.

## Send data

Send OTLP to the collector from workloads in the cluster:

- gRPC: `otel-collector.observability.svc.cluster.local:4317`
- HTTP: `http://otel-collector.observability.svc.cluster.local:4318`

Because Linkerd policy requires authenticated mesh TLS on these ports, local sender workloads should be in Linkerd-injected namespaces. For an intentionally non-meshed sender, add a narrow `ServerAuthorization` instead of exposing the collector through ingress.

The collector forwards:

- metrics to `victoria-metrics-single-server:8428/opentelemetry/v1/metrics`
- logs to `victoria-logs-single-server:9428/insert/opentelemetry/v1/logs`
- traces to `victoria-traces-single-server:10428/insert/opentelemetry/v1/traces`

## Linkerd telemetry

Deploy also installs a dedicated `linkerd-telemetry-collector` DaemonSet. It:

- scrapes Linkerd proxy admin ports and Linkerd control-plane admin ports with the collector's Prometheus receiver
- tails Linkerd control-plane logs and injected `linkerd-proxy` sidecar logs from node container logs
- writes Linkerd metrics to VictoriaMetrics
- writes Linkerd logs to VictoriaLogs

Local smoke verification checks that VictoriaMetrics has `up{job="linkerd-control-plane"}` samples:

```bash
just observability/smoke
```

## Optional S3 fan-out

To make cluster storage disposable while keeping raw telemetry elsewhere, enable collector fan-out to S3:

```bash
OBSERVABILITY_S3_BUCKET=my-observability-archive \
OBSERVABILITY_S3_REGION=us-east-1 \
OBSERVABILITY_S3_BASE_PREFIX=local-kind \
just observability/deploy-s3
```

This adds the OpenTelemetry `awss3` exporter to all pipelines. Objects are OTLP JSON, gzip-compressed, and partitioned like:

```text
s3://$OBSERVABILITY_S3_BUCKET/$OBSERVABILITY_S3_BASE_PREFIX/{metrics,logs,traces}/year=YYYY/month=MM/day=DD/hour=HH/...
```

Credentials are intentionally not stored in Git. For local kind tests, export AWS environment variables or create a Kubernetes Secret and add `extraEnvs` in `charts/observability/opentelemetry-collector-values.yaml`. In cloud, prefer pod identity/IRSA.

## Iceberg / DuckLake shape

Do not make Victoria* write Iceberg/DuckLake directly. Keep the hot path simple:

```text
apps -> OpenTelemetry Collector -> Victoria* hot store (30d, ephemeral)
                              \-> S3 raw OTLP archive
```

Then run a separate offline job to compact/convert S3 OTLP JSON into Apache Iceberg or DuckLake tables. That job can evolve independently and does not risk local observability ingestion.

Suggested table layout:

- database/schema: `observability`
- tables: `metrics_otlp`, `logs_otlp`, `traces_otlp`
- partitions: `signal`, `date`, `hour`, optionally `service.name`
- source path: `s3://bucket/base/{metrics,logs,traces}/year=*/month=*/day=*/hour=*`

## Cleanup

```bash
just observability/clean
```
