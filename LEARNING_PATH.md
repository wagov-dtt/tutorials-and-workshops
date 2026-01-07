# Learning Path

A suggested order for working through the examples, from beginner to advanced. Each section links to the corresponding example README for detailed instructions.

## Level 1: Local Kubernetes (No Cloud Required)

Start here. Everything runs on your laptop using Docker.

### 1.1 Deploy Local Databases

```bash
just deploy-local
```

**What you learn**: How k3d creates a local Kubernetes cluster, the Kustomize base/overlay pattern, and core Kubernetes resources (Pods, Deployments, Services, PVCs).

**Detailed guide**: [kustomize/README.md](kustomize/README.md)

**Files to study**:
- `kustomize/overlays/local/kustomization.yaml` - How overlays work
- `kustomize/databases/postgres.yaml` - A complete database deployment

**Exercises**:
1. Run `kubectl get pods -A` and identify each pod's purpose
2. Connect to Postgres: `kubectl exec -it postgres-0 -n databases -- psql -U postgres`
3. Inspect the storage: `kubectl get pvc -n databases`

---

### 1.2 DuckLake Analytics

```bash
just ducklake-test
```

**What you learn**: DuckDB for analytics workloads, S3-compatible storage with rclone, and Python integration with Kubernetes services.

**Detailed guide**: [ducklake/README.md](ducklake/README.md)

**Files to study**:
- `ducklake_test.py` - How to connect to K8s services from Python
- `ducklake/databases/rclone-s3.yaml` - Running rclone as an S3 server

**Exercises**:
1. Modify `ducklake_test.py` to run a different query
2. Port-forward and explore: `kubectl port-forward svc/rclone-s3 8080:80 -n databases`

---

### 1.3 CSI Volumes with rclone

```bash
just rclone-test
```

**What you learn**: CSI (Container Storage Interface) drivers, mounting cloud storage as filesystems, and StorageClasses with PersistentVolumes.

**Detailed guide**: [rclone/README.md](rclone/README.md)

**Files to study**:
- `rclone/base/deployment.yaml` - CSI volume in a pod spec
- `rclone/base/volumes.yaml` - StorageClass definition

**Exercises**:
1. Exec into the filebrowser pod and create a file
2. Verify the file appears in the rclone-serve storage

---

### 1.4 Drupal CMS

```bash
just drupal-setup
just drupal-login
```

**What you learn**: DDEV for local development, FrankenPHP (modern PHP runtime), and Composer/Drush for Drupal management.

**Detailed guide**: [drupal/README.md](drupal/README.md) (if available)

**Files to study**:
- `drupal/Caddyfile` - Web server and PHP config in one file
- `drupal/.ddev/config.yaml` - DDEV project settings

**Exercises**:
1. Create a new article in Drupal
2. Run `just vegeta https://drupal.ddev.site/` for load testing

---

## Level 2: AWS Basics (Requires AWS Account)

**Cost warning**: These examples cost money. Budget ~$80-100/month for EKS. Always destroy resources when done.

### 2.1 Create an EKS Cluster

```bash
just setup-eks
```

**What you learn**: Terraform basics, EKS Auto Mode (managed nodes), and AWS VPC networking.

**Detailed guide**: [eksauto/README.md](eksauto/README.md)

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

**What you learn**: EKS Pod Identity (credential-free AWS access), MySQL Shell for backups, and rclone for S3 operations.

**Detailed guide**: [s3-pod-identity/README.md](s3-pod-identity/README.md)

**Files to study**:
- `s3-pod-identity/base/namespace.yaml` - ServiceAccount setup
- `s3-pod-identity/jobs/backup.yaml` - Multi-container job pattern
- `eksauto/terraform/pod_identity.tf` - How Pod Identity is configured

**Exercises**:
1. Run `just s3-restore` to test the restore flow
2. Check S3 bucket contents in AWS Console
3. Explore the CSI mount: `kubectl exec -it debug -n s3-test -- sh`

---

### 2.3 External Secrets

```bash
just secrets-deploy
just secrets-test
```

**What you learn**: External Secrets Operator, AWS Secrets Manager integration, and the ClusterSecretStore pattern.

**Detailed guide**: [secrets/README.md](secrets/README.md)

**Files to study**:
- `secrets/base/clustersecretstore.yaml` - Backend configuration
- `secrets/base/externalsecret.yaml` - Secret reference

**Exercises**:
1. Update the secret in AWS Secrets Manager
2. Wait 5 minutes and verify the K8s secret updated
3. Create your own ExternalSecret

---

## Level 3: GitOps (Advanced)

### 3.1 ArgoCD

```bash
just argocd-ui
just argocd-deploy
```

**What you learn**: GitOps workflow, ApplicationSets, and AWS Identity Center integration.

**Detailed guide**: [argocd/README.md](argocd/README.md)

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

- [GETTING_STARTED.md](GETTING_STARTED.md) - First-time setup instructions
- [GLOSSARY.md](GLOSSARY.md) - Definitions of key terms
- [AGENTS.md](AGENTS.md) - For AI agents and contributors
