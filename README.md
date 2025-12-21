# tutorials-and-workshops

Concise, self-contained examples for DevOps/K8s activities. See [DevSecOps Induction](https://soc.cyber.wa.gov.au/training/devsecops-induction/) for structured training content.

Best local environment: [Project Bluefin](https://projectbluefin.io/) or [Debian on WSL2 with systemd](https://wiki.debian.org/InstallingDebianOn/Microsoft/Windows/SubsystemForLinux). Alternatively, use the included [devcontainer](.devcontainer/) with VS Code or DevPod.

```bash
just help      # Show core workflows
just --choose  # Fuzzy-pick any recipe
```

## Examples

| Directory | Purpose |
|-----------|---------|
| [kustomize/](kustomize/) | Base K8s manifests with local/training01 overlays (Postgres, MySQL, MongoDB, Elasticsearch) |
| [kustomize-s3-pod-identity/](kustomize-s3-pod-identity/) | EKS Pod Identity demo: MySQL backup → S3 → rclone copy → restore |
| [kustomize-argocd/](kustomize-argocd/) | ArgoCD + ApplicationSets for GitOps workflow |
| [kustomize-external-secrets/](kustomize-external-secrets/) | External Secrets Operator with AWS Secrets Manager |
| [kustomize-ducklake/](kustomize-ducklake/) | DuckLake (DuckDB + S3) local development setup |
| [eksauto/](eksauto/) | EKS Auto Mode cluster via Terraform (includes CloudWatch observability) |
| [drupal-cms-perftest/](drupal-cms-perftest/) | Drupal CMS testing: DDEV for local, k8s manifests for CSI mount validation |
| [rclone/](rclone/) | Rclone CSI driver examples for S3 mounts |

## Quick Start

### Local-only (no AWS required)

```bash
just deploy-local   # Start k3d + deploy databases
k9s                 # Explore the cluster
```

Other local examples:
```bash
just ducklake-test  # DuckLake with NY Taxi data
just rclone-lab     # rclone CSI S3 mount + filebrowser
```

Validate everything locally (runs lint, DDEV, k3d tests):
```bash
just validate-local
```

### EKS (requires AWS account)

```bash
just prereqs        # Check required tools
just awslogin       # Setup SSO
just setup-eks      # Create cluster via Terraform
just deploy         # Deploy core manifests
# ... do your training ...
just destroy-eks    # IMPORTANT: destroy when done
```

Full AWS validation (creates EKS cluster, runs S3 Pod Identity tests, cleans up):
```bash
just validate-aws
```

> **Cost warning**: EKS clusters cost ~$80-100/mo minimum. See [eksauto/](eksauto/) for Terraform details.

Once configured, deploy the [2048 game](https://docs.aws.amazon.com/eks/latest/userguide/quickstart.html#_deploy_the_2048_game_sample_application) to test cluster operations. Use [k9s](https://k9scli.io) to explore.

### Drupal examples

Drupal examples have their own justfile:
```bash
cd drupal-cms-perftest && just
```

## S3 Pod Identity Example

Demo of [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) - MySQL backup to S3 with rclone, no credentials in cluster. See [kustomize-s3-pod-identity/](kustomize-s3-pod-identity/) for full details.

```bash
just s3-pod-identity-test    # Full demo: sysbench → mysqlsh dump → S3 → rclone copy → restore
just s3-pod-identity-cleanup # Remove resources
```

## ArgoCD (GitOps)

ArgoCD EKS Capability is **enabled by default** with `just setup-eks`. It auto-discovers Identity Center - if not configured, Terraform fails with guidance.

For simple setups without Identity Center, disable with `terraform apply -var="enable_argocd=false"`.

```bash
just argocd-ui         # Get UI URL (login with Identity Center)
just argocd-deploy     # Deploy example ApplicationSet
```

See [kustomize-argocd/](kustomize-argocd/) for details.

## External Secrets Operator

Sync secrets from AWS Secrets Manager to Kubernetes. See [kustomize-external-secrets/](kustomize-external-secrets/) for details.

```bash
just external-secrets-deploy  # Install ESO + ClusterSecretStore
just external-secrets-test    # Verify secret sync
```

## Justfile Conventions

This repo uses [just](https://github.com/casey/just) as task runner with these patterns:

- `set dotenv-load` + `set export` - `.env` vars available everywhere
- `set shell := ["bash", "-lc"]` - login shell for mise/asdf tool integration
- Derived vars at top: `ACCOUNT := \`aws sts ...\`` then use `{{ACCOUNT}}` in recipes
- `[working-directory: 'path']` - run recipe in specified directory
- `-` prefix ignores errors, `@` prefix hides command echo
- `envsubst` for templating K8s manifests with `${VAR}` placeholders
- Private recipes prefixed with `_`

## Local Development

A close-to-production environment can be stood up locally with [k3d](https://k3d.io/stable/#quick-start) (better loadbalancer/storage defaults than minikube).

```bash
just deploy-local
```

This configures simple single-node databases for local testing:
- [PostgreSQL](kustomize/databases/postgres.yaml) (official postgres:16)
- [MySQL](kustomize/databases/mysql.yaml) (percona:8.0)
- [MongoDB](kustomize/databases/mongodb.yaml) (official mongo:7)
- [Elasticsearch](kustomize/databases/elasticsearch.yaml) (single-node dev mode, no operator)

## macOS Setup

For Apple Silicon Macs, use Colima + Rosetta for x86_64 devcontainers:

```bash
# Install tools
brew install colima docker docker-buildx devpod
mkdir -p ~/.docker/cli-plugins
ln -s $(which docker-buildx) ~/.docker/cli-plugins/docker-buildx

# Start VM with Rosetta (needs 2-3GB for k3d + databases)
softwareupdate --install-rosetta --agree-to-license
colima start --cpu 4 --memory 12 --vz-rosetta
devpod provider add docker

# Clone and launch devcontainer
gh repo clone wagov-dtt/tutorials-and-workshops
DOCKER_DEFAULT_PLATFORM=linux/amd64 devpod up tutorials-and-workshops
```
