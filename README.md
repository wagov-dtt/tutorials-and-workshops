# tutorials-and-workshops

Hands-on DevOps and Kubernetes examples. The default path is local-first: **kind**, **Helm**, **Linkerd**, and simple **Traefik static config** for browser-facing apps.

## First Run

Install [mise](https://mise.jdx.dev/) and Docker, then:

```bash
just prereqs
just databases/deploy
```

This creates the `tutorials` kind cluster, installs Linkerd, and deploys PostgreSQL, MySQL, MongoDB, and `whoami` with Helm.

New here? Use [GETTING_STARTED.md](GETTING_STARTED.md).

## Repository Shape

- `charts/` contains the Helm charts.
- Wrapper directories such as `databases/`, `rclone/`, and `collaboration-stack/` contain small `just` recipes and README files.
- `shared.just` owns shared local platform helpers: kind + Linkerd.
- AWS examples live in `eksauto/`, `s3-pod-identity/`, and `secrets/`.

Local Kubernetes examples use this pattern:

```text
kind cluster -> Linkerd mesh -> Helm chart -> optional Traefik edge
```

Internal services stay ClusterIP-only. Browser-facing stacks expose one Traefik service and document Linkerd policy between workloads.

## Common Commands

| Goal | Command | Cloud? |
|------|---------|--------|
| Install tools from `mise.toml` | `just prereqs` | No |
| Local databases | `just databases/deploy` | No |
| Local S3 filesystem mount | `just rclone/rclone-test` | No |
| Collaboration stack + SSO | `just collaboration-stack/deploy` | No |
| Local Drupal CMS | `just drupal/drupal-setup` | No |
| EKS cluster | `just eksauto/setup-eks` | Yes |
| Deploy database chart to EKS | `just eksauto/deploy` | Yes |
| EKS S3 backup + AWS S3 Files | `just s3-pod-identity/s3-test` | Yes |
| External Secrets demo | `just secrets/secrets-deploy` | Yes |

Run `just` to list all recipes.

## Examples

| Directory | What it teaches | Level |
|-----------|-----------------|-------|
| [databases/](databases/) | Helm deployment to kind with Linkerd baseline | Beginner |
| [rclone/](rclone/) | rclone CSI and S3-compatible mounts | Intermediate |
| [collaboration-stack/](collaboration-stack/) | Traefik routing, Keycloak edge SSO, Linkerd policy | Intermediate |
| [drupal-hugo/](drupal-hugo/) | Drupal/PHP development with DDEV | Intermediate |
| [restic/](restic/) | Encrypted GitHub org backups to S3 | Intermediate |
| [eksauto/](eksauto/) | EKS Auto Mode cluster via Terraform | Advanced |
| [s3-pod-identity/](s3-pod-identity/) | EKS Pod Identity, MySQL backups, AWS S3 Files | Advanced |
| [secrets/](secrets/) | External Secrets with AWS Secrets Manager | Advanced |
| [argocd/](argocd/) | Note on reconciling these Helm charts with ArgoCD | Reference |

Recommended order: [LEARNING_PATH.md](LEARNING_PATH.md).

## Validation

```bash
just lint           # Helm render/lint + Terraform validate + Trivy
just validate-local # local kind examples plus Drupal check
```

Validate a chart directly:

```bash
helm lint charts/databases
helm template databases charts/databases >/tmp/databases.yaml
```

For EKS/S3 work, render before touching a live cluster:

```bash
helm template s3-pod-identity charts/s3-pod-identity \
  --set aws.region=us-east-1 \
  --set bucket=test-123456789012 \
  --set s3files.fileSystemId=fs-12345678 >/tmp/s3-pod-identity.yaml
```

Expected EKS S3 Files pattern: `provisioner: efs.csi.aws.com`, `storageClassName: s3files-s3`, and no `rclone.csi.veloxpack.io`. The `rclone/` demo is local-only.

## AWS Cost Warning

EKS costs money. Destroy cloud labs when done:

```bash
just eksauto/destroy-eks
```

## Documentation

| Document | Use it for |
|----------|------------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | First local walkthrough |
| [LEARNING_PATH.md](LEARNING_PATH.md) | Recommended order |
| [GLOSSARY.md](GLOSSARY.md) | Terms and concepts |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Repo conventions |
| [ISSUES.md](ISSUES.md) | Historical audit backlog |

## Links

- [kind](https://kind.sigs.k8s.io/)
- [Helm](https://helm.sh/docs/)
- [Linkerd](https://linkerd.io/2/getting-started/)
- [Just](https://github.com/casey/just)
- [AWS-managed ArgoCD on EKS](https://docs.aws.amazon.com/eks/latest/userguide/argocd.html)

## License

[MIT](LICENSE)
