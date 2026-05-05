---
title: "Learning Path"
description: "Recommended order for local, AWS, and GitOps examples."
weight: 20
icon: "route"
---

A suggested order for working through the examples, from beginner to advanced. Each section links to the corresponding example README for detailed instructions. For setup steps and security validation habits, see [Getting Started](_index.md).

## Level 1: Local Kubernetes (No Cloud Required)

Start here. Everything runs on your laptop using Docker.

### 1.1 Deploy Local Databases

```bash
just deploy-local
```

**What you learn**: How k3d creates a local Kubernetes cluster, the Kustomize base/overlay pattern, and core Kubernetes resources (Pods, Deployments, Services, PVCs).

**Detailed guide**: [Kustomize](examples/kustomize.md)

**Files to study**:
- `kustomize/overlays/local/kustomization.yaml` - How overlays work
- `kustomize/databases/postgres.yaml` - A complete database deployment

**Exercises**:
1. Run `kubectl get pods -A` and identify each pod's purpose
2. Connect to Postgres: `kubectl exec -it postgres-0 -n databases -- psql -U postgres`
3. Inspect the storage: `kubectl get pvc -n databases`

---

### 1.2 CSI Volumes with rclone

```bash
just rclone-test
```

**What you learn**: CSI (Container Storage Interface) drivers, mounting cloud storage as filesystems, and StorageClasses with PersistentVolumes.

**Detailed guide**: [rclone CSI](examples/rclone.md)

**Files to study**:
- `rclone/base/deployment.yaml` - CSI volume in a pod spec
- `rclone/base/volumes.yaml` - StorageClass definition

**Exercises**:
1. Exec into the filebrowser pod and create a file
2. Verify the file appears in the rclone-serve storage

---

### 1.3 Apps SSO (BookStack + Kanboard + Woodpecker)

```bash
just apps-sso
```

**What you learn**: Running web apps as Kubernetes Deployments, connecting apps to backing storage, and protecting multiple app domains with one Keycloak + oauth2-proxy SSO pattern behind a static Traefik edge.

**Detailed guide**: [Apps SSO](examples/apps-sso.md)

**Files to study**:
- `apps-sso/apps.yaml` - BookStack and Kanboard Deployments and Services
- `apps-sso/woodpecker.yaml` - Woodpecker CI Deployment and Service
- `apps-sso/mariadb.yaml` - Database Deployment for BookStack
- `apps-sso/keycloak.yaml` - Demo realm, groups, OIDC client, and user
- `apps-sso/oauth2-proxy.yaml` - Shared oauth2-proxy Keycloak OIDC configuration
- `apps-sso/traefik.yaml` - Static Traefik routers, forwardAuth middleware, and NodePort Service

**Exercises**:
1. Log in through Keycloak as `auditor` and open the BookStack, Kanboard, and Woodpecker domains
2. Inspect Traefik forwardAuth and identify which headers carry user, email, groups, and access token
3. Create a BookStack page and a Kanboard task
4. Delete a pod and observe what happens to `emptyDir` demo data

---

### 1.4 Drupal CMS

```bash
just drupal-setup
cd drupal
ddev drush user:login  # Get admin login
```

**What you learn**: DDEV for local development, FrankenPHP (modern PHP runtime), and Composer/Drush for Drupal management.

**Detailed guide**: [Drupal Hugo/DDEV](examples/drupal.md)

**Files to study**:
- `drupal/Caddyfile` - Web server and PHP config in one file
- `drupal/.ddev/config.yaml` - DDEV project settings

**Exercises**:
1. Create a new article in Drupal
2. Generate test content: `cd drupal && ddev drush php:script scripts/generate_news_content.php`
3. Run performance test: `just drupal-test`

**Daily commands** (use DDEV directly):
```bash
cd drupal
ddev start              # Start environment
ddev stop               # Stop environment
ddev drush user:login   # Get admin login link
```

---

## Level 2: AWS Basics (Requires AWS Account)

**Cost warning**: EKS clusters cost money—see [eksauto/README.md](examples/eksauto.md) for cost breakdown. Always destroy when done.

### 2.1 Create an EKS Cluster

```bash
just setup-eks
```

**What you learn**: Terraform basics, EKS Auto Mode (managed nodes), and AWS VPC networking.

**Detailed guide**: [EKS Auto Mode](examples/eksauto.md)

**Files to study**:
- `eksauto/terraform/main.tf` - VPC and EKS definition
- `eksauto/terraform/outputs.tf` - Getting cluster info

**Exercises**:
1. Run `terraform plan` to preview what will be created
2. Explore the cluster: `kubectl get nodes`
3. Check AWS Console for the VPC and subnets

---

### 2.2 S3 Pod Identity

```bash
just s3-test
```

**What you learn**: EKS Pod Identity (credential-free AWS access), MySQL Shell for backups, rclone for S3 object operations, and AWS S3 Files/EFS CSI for POSIX-style S3 inspection on EKS.

**Detailed guide**: [S3 Pod Identity](examples/s3-pod-identity.md)

**Files to study**:
- `s3-pod-identity/base/namespace.yaml` - ServiceAccount setup
- `s3-pod-identity/base/s3files.yaml` - AWS S3 Files StorageClass rendered for EFS CSI
- `s3-pod-identity/jobs/backup.yaml` - Multi-container job pattern
- `eksauto/terraform/pod_identity.tf` - How Pod Identity is configured
- `eksauto/terraform/s3files.tf` - S3 Files file system, mount targets, and CSI IAM roles

**Exercises**:
1. Run `just s3-restore` to test the restore flow
2. Check S3 bucket contents in AWS Console
3. Explore the AWS S3 Files mount: `kubectl exec -it debug -n s3-test -- sh`

---

### 2.3 External Secrets

```bash
just secrets-deploy
just secrets-test
```

**What you learn**: External Secrets Operator, AWS Secrets Manager integration, and the ClusterSecretStore pattern.

**Detailed guide**: [External Secrets](examples/secrets.md)

**Files to study**:
- `secrets/base/clustersecretstore.yaml` - Backend configuration
- `secrets/base/externalsecret.yaml` - Secret reference

**Exercises**:
1. Update the secret in AWS Secrets Manager
2. Wait 5 minutes and verify the K8s secret updated
3. Create your own ExternalSecret

---

## Level 3: GitOps (Optional)

### 3.1 ArgoCD

> **Requires AWS Identity Center.** Skip if Identity Center isn't configured.

```bash
# First enable ArgoCD
cd eksauto/terraform && terraform apply -var="enable_argocd=true"

# Then use ArgoCD
just argocd-ui
just argocd-deploy
```

**What you learn**: GitOps workflow, ApplicationSets, and AWS Identity Center integration.

**Detailed guide**: [ArgoCD](examples/argocd.md)

**Files to study**:
- `argocd/base/applicationset.yaml` - How apps are discovered
- `argocd/apps/guestbook/` - Example application

**Exercises**:
1. Add a new app under `argocd/apps/`
2. Push to git and watch ArgoCD sync
3. Make a manual change and watch ArgoCD revert it

---

## Cleanup Checklist

When you're done learning:

```bash
# Level 1 cleanup
k3d cluster delete tutorials
just drupal-reset

# Level 2-3 cleanup (IMPORTANT - stops AWS charges)
just destroy-eks
```

Verify in AWS Console that:
- [ ] No EKS clusters running
- [ ] No EC2 instances running
- [ ] No NAT Gateways (these are expensive!)

---

## See Also

- [GETTING_STARTED.md](_index.md) - First-time setup instructions
- [GLOSSARY.md](glossary.md) - Definitions of key terms
