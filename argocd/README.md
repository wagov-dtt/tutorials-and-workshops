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

ArgoCD is enabled by default via Terraform. When you run `just setup-eks`:

1. Terraform auto-discovers the Identity Center instance
2. Creates the ArgoCD EKS Capability (AWS-managed)
3. Prints the ArgoCD UI URL

If Identity Center isn't configured, Terraform fails with clear guidance.

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

By default, ArgoCD is created without RBAC mappings (anyone in Identity Center can view). To add an admin:

```bash
# Get the Identity Center user ID
STORE_ID=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)
aws identitystore list-users --identity-store-id $STORE_ID

# Recreate with admin user
cd eksauto/terraform
terraform apply -var="idc_admin_user_id=YOUR_USER_ID"
```

## Disabling ArgoCD

To disable ArgoCD (no Identity Center or not needed):

```bash
just setup-eks ARGOCD=false
# Or directly:
cd eksauto/terraform && terraform apply -var="enable_argocd=false"
```

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#31-argocd) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#gitops) - GitOps definition
- [eksauto/](../eksauto/) - Terraform that creates the ArgoCD capability
- [EKS Capability for ArgoCD](https://docs.aws.amazon.com/eks/latest/userguide/argocd-comparison.html) - AWS documentation
- [ArgoCD documentation](https://argo-cd.readthedocs.io/) - Official ArgoCD docs
