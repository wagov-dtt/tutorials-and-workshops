# Learning Path

A suggested order for working through the examples, from beginner to advanced.

## Level 1: Local Kubernetes (No Cloud Required)

Start here. Everything runs on your laptop using Docker.

### 1.1 Deploy Local Databases

```bash
just deploy-local
```

**What you learn:**
- How k3d creates a local Kubernetes cluster
- Kustomize base/overlay pattern
- Kubernetes resources: Pods, Deployments, Services, PVCs

**Files to study:**
- `kustomize/overlays/local/kustomization.yaml` - How overlays work
- `kustomize/databases/postgres.yaml` - A complete database deployment

**Exercises:**
1. Run `kubectl get pods -A` and understand each pod
2. Connect to Postgres: `kubectl exec -it postgres-0 -n databases -- psql -U postgres`
3. Look at the PVC: `kubectl get pvc -n databases`

---

### 1.2 DuckLake Analytics

```bash
just ducklake-test
```

**What you learn:**
- DuckDB for analytics workloads
- S3-compatible storage (rclone-serve)
- Python + Kubernetes integration

**Files to study:**
- `ducklake_test.py` - How to connect to K8s services from Python
- `ducklake/databases/rclone-s3.yaml` - Running rclone as an S3 server

**Exercises:**
1. Modify `ducklake_test.py` to run a different query
2. Port-forward and explore: `kubectl port-forward svc/rclone-s3 8080:80 -n databases`

---

### 1.3 CSI Volumes with rclone

```bash
just rclone-test
```

**What you learn:**
- CSI (Container Storage Interface) drivers
- Mounting cloud storage as filesystems
- StorageClasses and PersistentVolumes

**Files to study:**
- `rclone/base/deployment.yaml` - CSI volume in a pod spec
- `rclone/base/volumes.yaml` - StorageClass definition

**Exercises:**
1. Exec into the filebrowser pod and create a file
2. Check if it appears in the rclone-serve storage

---

### 1.4 Drupal CMS

```bash
just drupal-setup
just drupal-login
```

**What you learn:**
- DDEV for local development
- FrankenPHP (modern PHP runtime)
- Composer and Drush for Drupal

**Files to study:**
- `drupal/Caddyfile` - Web server + PHP config in one file
- `drupal/.ddev/config.yaml` - DDEV project settings

**Exercises:**
1. Create a new article in Drupal
2. Run `just vegeta https://drupal.ddev.site/` for load testing

---

## Level 2: AWS Basics (Requires AWS Account)

⚠️ **These examples cost money.** Budget ~$80-100/month for EKS. Always destroy when done.

### 2.1 Create an EKS Cluster

```bash
just setup-eks
```

**What you learn:**
- Terraform basics
- EKS Auto Mode (managed nodes)
- AWS VPC networking

**Files to study:**
- `eksauto/terraform/main.tf` - VPC + EKS definition
- `eksauto/terraform/outputs.tf` - Getting cluster info

**Exercises:**
1. Run `terraform plan` to see what will be created
2. Explore the cluster: `kubectl get nodes`
3. Check AWS Console for the VPC and subnets created

---

### 2.2 S3 Pod Identity

```bash
just s3-test
```

**What you learn:**
- EKS Pod Identity (no credentials in cluster)
- MySQL Shell for backups
- rclone for S3 operations

**Files to study:**
- `s3-pod-identity/base/namespace.yaml` - ServiceAccount setup
- `s3-pod-identity/jobs/backup.yaml` - Multi-container job pattern
- `eksauto/terraform/pod_identity.tf` - How Pod Identity is configured

**Exercises:**
1. Run `just s3-restore` to test the restore flow
2. Check S3 bucket contents in AWS Console
3. Try `kubectl exec -it debug -n s3-test -- sh` to explore the CSI mount

---

### 2.3 External Secrets

```bash
just secrets-deploy
just secrets-test
```

**What you learn:**
- External Secrets Operator
- AWS Secrets Manager
- ClusterSecretStore pattern

**Files to study:**
- `secrets/base/clustersecretstore.yaml` - Backend configuration
- `secrets/base/externalsecret.yaml` - Secret reference

**Exercises:**
1. Update the secret in AWS Secrets Manager
2. Wait 5 minutes and check if K8s secret updated
3. Create your own ExternalSecret

---

## Level 3: GitOps (Advanced)

### 3.1 ArgoCD

```bash
just argocd-ui
just argocd-deploy
```

**What you learn:**
- GitOps workflow
- ApplicationSets
- AWS Identity Center integration

**Files to study:**
- `argocd/base/applicationset.yaml` - How apps are discovered
- `argocd/apps/guestbook/` - Example application

**Exercises:**
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

## Reference

| Level | Example | Difficulty | AWS Required | Est. Time |
|-------|---------|------------|--------------|-----------|
| 1.1 | deploy-local | ⭐ | No | 15 min |
| 1.2 | ducklake-test | ⭐ | No | 20 min |
| 1.3 | rclone-test | ⭐⭐ | No | 15 min |
| 1.4 | drupal-setup | ⭐⭐ | No | 30 min |
| 2.1 | setup-eks | ⭐⭐⭐ | Yes | 20 min |
| 2.2 | s3-test | ⭐⭐⭐ | Yes | 30 min |
| 2.3 | secrets-deploy | ⭐⭐⭐ | Yes | 20 min |
| 3.1 | argocd | ⭐⭐⭐⭐ | Yes | 45 min |
