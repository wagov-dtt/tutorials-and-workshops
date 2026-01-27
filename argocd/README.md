# argocd/

> GitOps with ArgoCD on EKS. Automated deployments where Git is the source of truth.

## When to Use ArgoCD

ArgoCD is optional. For simple setups, `kubectl apply` or `helm upgrade` works fine. ArgoCD adds value when:

- Multiple people deploy to the same cluster
- Audit trails are needed for compliance
- Self-healing (auto-revert manual changes) matters
- You manage multiple clusters

**Skip ArgoCD if**: You're learning solo or running a simple single-cluster setup.

## Quick Start

```bash
# ArgoCD is created automatically with the cluster
just setup-eks

# Get ArgoCD UI URL
just argocd-ui

# Deploy example ApplicationSet
just argocd-deploy
```

Login to the UI with your Identity Center credentials.

## How It Works

ArgoCD EKS Capability is **disabled by default** (requires Identity Center). To enable:

```bash
# Enable during cluster creation
cd eksauto/terraform
terraform apply -var="enable_argocd=true"

# Or create capability after cluster exists
just argocd-create
```

If Identity Center isn't configured, capability creation will fail.

## What Gets Deployed

| Resource | Purpose |
|----------|---------|
| ArgoCD capability | AWS-managed ArgoCD control plane |
| ApplicationSet | Watches `apps/` directory in this repo |
| Example app (guestbook) | Simple app to demonstrate GitOps |

## Directory Structure

```
argocd/
├── base/
│   ├── namespace.yaml        # argocd namespace
│   └── applicationset.yaml   # Watches apps/ directory
├── apps/
│   └── guestbook/            # Example app
└── kustomization.yaml
```

## Adding a New App

1. Create a directory under `apps/` with a `kustomization.yaml`
2. Commit and push
3. ArgoCD syncs automatically (or click Sync in the UI)

## Adding an Admin User

By default, anyone in Identity Center can view ArgoCD. To add yourself as admin:

```bash
just argocd-ui   # Auto-adds current SSO user as admin and prints URL
```

## Disabling ArgoCD

ArgoCD is disabled by default. If you enabled it and want to disable:

```bash
just argocd-delete
# Or via Terraform:
cd eksauto/terraform && terraform apply -var="enable_argocd=false"
```

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#31-argocd) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#gitops) - GitOps definition
- [eksauto/](../eksauto/) - Terraform that creates the ArgoCD capability
- [EKS Capability for ArgoCD](https://docs.aws.amazon.com/eks/latest/userguide/argocd-comparison.html) - AWS documentation
- [ArgoCD documentation](https://argo-cd.readthedocs.io/) - Official ArgoCD docs
