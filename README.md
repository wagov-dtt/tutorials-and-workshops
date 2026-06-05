# tutorials-and-workshops

Hands-on DevOps and Kubernetes labs. Start local, learn the shape, then move to AWS only when you are ready for cost and account blast radius.

The default local platform is:

```text
kind cluster -> Linkerd mesh -> Helm chart -> optional Traefik edge
```

Internal services stay `ClusterIP` by default. Browser-facing stacks expose one temporary/local edge and document the Linkerd policy between workloads.

## Fast start

Install [mise](https://mise.jdx.dev/) and [Docker](https://docs.docker.com/get-docker/), then run:

```bash
just prereqs
just doctor
just databases/deploy
just databases/smoke
```

This creates the `tutorials` [kind](https://kind.sigs.k8s.io/) cluster, installs [Linkerd](https://linkerd.io/2/), and deploys PostgreSQL, MySQL, MongoDB, and a `whoami` debug app with [Helm](https://helm.sh/docs/).

New here? Follow [GETTING_STARTED.md](GETTING_STARTED.md).

## What is in this repo?

| Path | Purpose |
|------|---------|
| `charts/` | Repo-owned Helm charts for the labs |
| `databases/`, `rclone/`, `collaboration-stack/`, `observability/` | Local kind lab wrappers, docs, and `just` recipes |
| `drupal-hugo/` | Drupal CMS/DDEV example |
| `restic/` | GitHub organization backup example using restic and S3 |
| `eksauto/`, `s3-pod-identity/`, `secrets/` | AWS/EKS labs |
| `shared.just` | Shared helpers for kind, Linkerd, and local platform setup |
| `justfile` | Top-level command entry point |

## Common commands

| Goal | Command | Creates cloud resources? |
|------|---------|--------------------------|
| Install repo tools | `just prereqs` | No |
| Preflight report | `just doctor` | No |
| Curated command map | `just commands` | No |
| Fast local checks | `just check` | No |
| Local database lab | `just databases/deploy` | No |
| Local S3-like filesystem mount | `just rclone/deploy` | No |
| Collaboration apps | `just collab::deploy` | No |
| Local observability | `just observability/deploy` | No |
| Drupal CMS | `just drupal::deploy` | No |
| EKS Auto Mode cluster | `just eksauto/setup-eks` | Yes |
| Database chart on EKS | `just eksauto/deploy` | Yes |
| S3 backup + Pod Identity | `just s3-pod-identity/deploy` | Yes |
| External Secrets demo | `just secrets/deploy` | Yes |

Run `just` to list every recipe.

## Labs

| Lab | What it teaches | Level |
|-----|-----------------|-------|
| [databases/](databases/) | Helm deployment to kind with a Linkerd baseline | Beginner |
| [rclone/](rclone/) | CSI concepts and S3-compatible mounts | Intermediate |
| [collaboration-stack/](collaboration-stack/) | Traefik routing, local app auth, optional Keycloak/oauth2-proxy SSO, Linkerd policy | Intermediate |
| [observability/](observability/) | VictoriaMetrics/Logs/Traces, Grafana, OpenTelemetry, optional S3 archive | Intermediate |
| [drupal-hugo/](drupal-hugo/) | Drupal/PHP local development with DDEV | Intermediate |
| [restic/](restic/) | Encrypted GitHub org backups to S3 | Intermediate |
| [eksauto/](eksauto/) | EKS Auto Mode with Terraform | Advanced |
| [s3-pod-identity/](s3-pod-identity/) | EKS Pod Identity, MySQL backups, AWS S3 Files | Advanced |
| [secrets/](secrets/) | External Secrets Operator with AWS Secrets Manager | Advanced |
| [argocd/](argocd/) | Notes on reconciling these Helm charts with ArgoCD | Reference |

Recommended order: [LEARNING_PATH.md](LEARNING_PATH.md).

## Validate

```bash
just check          # fast local just/Helm checks
just check-cloud    # Terraform validate + cloud chart renders
just check-security # Trivy config scan
just lint           # render + Terraform + security checks
just validate-local # deploy and smoke-test local examples plus Drupal check
```

Validate one chart directly:

```bash
helm lint charts/databases
helm template databases charts/databases >/tmp/databases.yaml
```

Render EKS/S3 examples before touching a live cluster:

```bash
helm template s3-pod-identity charts/s3-pod-identity \
  --set-string aws.region="${AWS_REGION:-$(aws configure get region)}" \
  --set bucket=test-123456789012 \
  --set s3files.fileSystemId=fs-12345678 >/tmp/s3-pod-identity.yaml
```

Expected EKS S3 Files pattern: `provisioner: efs.csi.aws.com`, `storageClassName: s3files-s3`, and no `rclone.csi.veloxpack.io`. The `rclone/` demo is local-only.

## AWS cost warning

EKS costs money. Before cloud labs, run:

```bash
just aws-preflight
```

Destroy cloud labs when done:

```bash
just eksauto/destroy-eks
```

## Documentation map

| Document | Use it for |
|----------|------------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | First local walkthrough |
| [LEARNING_PATH.md](LEARNING_PATH.md) | Recommended lab order |
| [COMMANDS.md](COMMANDS.md) | Command index |
| [GLOSSARY.md](GLOSSARY.md) | Terms and external references |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Repo conventions |
| [ISSUES.md](ISSUES.md) | Historical audit backlog |
| [REVIEW.md](REVIEW.md) | Generated code quality review |

## Useful external docs

- [just command runner](https://just.systems/man/en/)
- [mise tool version manager](https://mise.jdx.dev/)
- [kind local Kubernetes](https://kind.sigs.k8s.io/)
- [kubectl reference](https://kubernetes.io/docs/reference/kubectl/)
- [Helm docs](https://helm.sh/docs/)
- [Linkerd docs](https://linkerd.io/2/)
- [Traefik file provider](https://doc.traefik.io/traefik/providers/file/)
- [AWS EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [ArgoCD docs](https://argo-cd.readthedocs.io/)

## License

[Apache 2.0](LICENSE)
