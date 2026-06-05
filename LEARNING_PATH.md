# Learning Path

Recommended order: local first, then AWS. The local labs teach the mechanics without cloud cost; the AWS labs add IAM, EKS, S3, and managed services.

## Level 1: local Kubernetes

### 1.1 Databases on kind

```bash
just databases/deploy
just databases/smoke
kubectl get pods -n databases
```

You learn:

- kind cluster creation
- Linkerd injection and policy baseline
- Helm releases
- simple stateful services

Read: [databases/README.md](databases/README.md)

Study:

- `charts/databases/Chart.yaml`
- `charts/databases/templates/postgres.yaml`
- `charts/databases/templates/mysql.yaml`
- `charts/databases/templates/mongodb.yaml`
- `shared.just` (`_kind`, `_linkerd`, `_platform`)

References: [kind](https://kind.sigs.k8s.io/), [Helm](https://helm.sh/docs/), [Linkerd](https://linkerd.io/2/)

---

### 1.2 rclone CSI volumes

```bash
just rclone/deploy
just rclone/smoke
kubectl -n rclone port-forward svc/filebrowser 8080:80
```

You learn:

- CSI driver shape
- S3-compatible storage mounts
- Helm deployment for a demo workload
- Linkerd policy around storage-facing services

Read: [rclone/README.md](rclone/README.md)

Study:

- `charts/rclone-demo/templates/deployment.yaml`
- `charts/rclone-demo/templates/volumes.yaml`
- `charts/rclone-demo/templates/linkerd-policy.yaml`

References: [Kubernetes CSI](https://kubernetes-csi.github.io/docs/), [rclone](https://rclone.org/docs/)

---

### 1.3 Collaboration stack

```bash
just collab::deploy
just collab::smoke
kubectl -n collaboration port-forward svc/traefik 8080:80
```

You learn:

- Traefik file/static routing
- local app auth defaults
- optional Keycloak/oauth2-proxy ForwardAuth path
- Linkerd policy between edge, identity, apps, and databases

Read: [collaboration-stack/README.md](collaboration-stack/README.md)

Study:

- `charts/collaboration-stack/templates/traefik.yaml`
- `charts/collaboration-stack/templates/identity.yaml`
- `charts/collaboration-stack/templates/linkerd-policy.yaml`

References: [Traefik file provider](https://doc.traefik.io/traefik/providers/file/), [Keycloak docs](https://www.keycloak.org/documentation), [oauth2-proxy docs](https://oauth2-proxy.github.io/oauth2-proxy/)

---

### 1.4 Observability

```bash
just observability/deploy
just observability/smoke
just observability/ui
```

You learn:

- OpenTelemetry collector fan-out
- VictoriaMetrics, VictoriaLogs, and VictoriaTraces as a short-retention hot store
- Grafana datasource provisioning
- Linkerd policy for telemetry paths

Read: [observability/README.md](observability/README.md)

References: [OpenTelemetry](https://opentelemetry.io/docs/), [Grafana](https://grafana.com/docs/), [VictoriaMetrics](https://docs.victoriametrics.com/)

---

### 1.5 Drupal CMS

```bash
just drupal::deploy
just drupal::smoke
cd drupal-hugo
ddev drush user:login
```

You learn:

- DDEV local PHP/Drupal workflow
- Composer-managed Drupal project setup
- Drush basics

Read: [drupal-hugo/README.md](drupal-hugo/README.md)

References: [DDEV docs](https://docs.ddev.com/en/stable/), [Drupal User Guide](https://www.drupal.org/docs/user_guide/en/index.html), [Drush docs](https://www.drush.org/)

## Level 2: AWS examples

Run `just aws-preflight` before any cloud lab.

### 2.1 EKS Auto Mode

```bash
just eksauto/setup-eks
just eksauto/smoke
just eksauto/deploy
```

You learn:

- Terraform-managed EKS
- S3-backed Terraform state
- EKS Auto Mode and add-ons
- cleanup and cost boundaries

Read: [eksauto/README.md](eksauto/README.md)

References: [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html), [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### 2.2 S3 Pod Identity

```bash
just s3-pod-identity/deploy
just s3-pod-identity/smoke
just s3-pod-identity/s3-restore
```

You learn:

- EKS Pod Identity
- IAM roles scoped to Kubernetes ServiceAccounts
- MySQL Shell dump/restore
- rclone server-side copy
- AWS S3 Files debug mounts

Read: [s3-pod-identity/README.md](s3-pod-identity/README.md)

References: [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html), [MySQL Shell utilities](https://dev.mysql.com/doc/mysql-shell/8.0/en/mysql-shell-utilities.html), [rclone S3 backend](https://rclone.org/s3/)

### 2.3 External Secrets

```bash
just secrets/deploy
just secrets/smoke
```

You learn:

- External Secrets Operator
- namespace-scoped `SecretStore`
- syncing AWS Secrets Manager values into Kubernetes

Read: [secrets/README.md](secrets/README.md)

References: [External Secrets Operator](https://external-secrets.io/latest/), [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)

## Deployment model

The repo-owned Kubernetes examples live under `charts/`. Deploy them directly with `helm upgrade --install`, or reconcile them from an orchestration cluster with ArgoCD. See [argocd/README.md](argocd/README.md).
