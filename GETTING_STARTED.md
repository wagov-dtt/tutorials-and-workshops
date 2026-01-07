# Getting Started

New to DevOps or Kubernetes? Start here.

## What You'll Learn

This repo teaches modern infrastructure patterns through hands-on examples:

- **Kubernetes basics** - Deploying apps, databases, and services
- **Kustomize** - Managing config without templating
- **S3 and cloud storage** - Backups, mounts, and object storage
- **GitOps** - Automated deployments with ArgoCD
- **Infrastructure as Code** - Creating cloud resources with Terraform

## Prerequisites

You need these installed:

| Tool | What it does | Install |
|------|--------------|---------|
| [mise](https://mise.jdx.dev/) | Manages tool versions | `curl https://mise.run \| sh` |
| [Docker](https://docs.docker.com/get-docker/) | Runs containers | Follow Docker docs |

That's it! Everything else (kubectl, k3d, terraform, etc.) is installed automatically via `mise`.

## Your First Commands

```bash
# Clone the repo
git clone https://github.com/user/tutorials-and-workshops
cd tutorials-and-workshops

# Install all tools
just prereqs

# Create a local Kubernetes cluster and deploy databases
just deploy-local
```

This creates a local [k3d](https://k3d.io/) cluster (Kubernetes in Docker) with PostgreSQL, MySQL, MongoDB, and Elasticsearch running.

## Explore What You Built

```bash
# See all running pods
kubectl get pods -A

# Open k9s (terminal UI for Kubernetes)
k9s
```

In k9s, press `0` to see all namespaces, arrow keys to navigate, `d` to describe a pod, `l` for logs, `q` to quit.

## What Just Happened?

1. `just prereqs` - Installed kubectl, k3d, helm, and other tools via mise
2. `just deploy-local` - Created a k3d cluster called "tutorials"
3. Applied Kubernetes manifests from `kustomize/` to deploy databases

The magic is in `kustomize/overlays/local/kustomization.yaml` - it combines base manifests with local-specific settings.

## Next Steps

### Beginner Path (No AWS Required)

| Order | Command | What You Learn |
|-------|---------|----------------|
| 1 | `just deploy-local` | Kubernetes basics, Kustomize |
| 2 | `just ducklake-test` | DuckDB analytics, S3-compatible storage |
| 3 | `just rclone-test` | Mounting cloud storage as filesystems |
| 4 | `just drupal-setup` | Local PHP development with DDEV |

### Intermediate Path (Requires AWS)

After you're comfortable with local examples:

| Order | Command | What You Learn |
|-------|---------|----------------|
| 1 | `just setup-eks` | Terraform, EKS Auto Mode |
| 2 | `just s3-test` | Pod Identity, IAM roles |
| 3 | `just secrets-deploy` | External Secrets Operator |
| 4 | `just argocd-ui` | GitOps with ArgoCD |

⚠️ **Cost warning**: EKS costs ~$80-100/month. Always run `just destroy-eks` when done!

## Key Concepts

### What is Kubernetes?

Kubernetes (K8s) runs containers across multiple machines. You describe what you want (YAML manifests), and K8s makes it happen.

```yaml
# A simple pod - one container running nginx
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: web
      image: nginx
```

### What is Kustomize?

Kustomize lets you customize Kubernetes YAML without templates. Instead of `{{ .Values.replicas }}`, you write patches:

```yaml
# kustomization.yaml - combines resources and patches
resources:
  - deployment.yaml
patches:
  - patch-replicas.yaml
```

It's built into kubectl: `kubectl apply -k ./my-directory/`

### What is Just?

[Just](https://github.com/casey/just) is a command runner (like Make, but simpler). The `justfile` contains all recipes:

```bash
just              # List all recipes
just deploy-local # Run a specific recipe
```

## Troubleshooting

### "command not found: kubectl"

Run `just prereqs` to install tools, then restart your shell or run `source ~/.bashrc`.

### "Cannot connect to the Docker daemon"

Start Docker Desktop, or on Linux: `sudo systemctl start docker`

### k3d cluster won't start

```bash
# Delete and recreate
k3d cluster delete tutorials
just deploy-local
```

### Pods stuck in "Pending"

Usually waiting for resources. Check events:
```bash
kubectl describe pod <pod-name> -n <namespace>
```

## Getting Help

- `just` - Lists all available commands with descriptions
- Each directory has a README.md explaining that example
- Check LEARNING_PATH.md for the recommended order

## Cleanup

```bash
# Stop local cluster (preserves data)
k3d cluster stop tutorials

# Delete local cluster completely
k3d cluster delete tutorials

# Stop Drupal
just drupal-stop
```
