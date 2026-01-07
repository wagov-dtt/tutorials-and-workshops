# Glossary

Quick definitions for terms used throughout this repo. For deeper understanding, follow the links to official documentation.

## Kubernetes Concepts

### CSI (Container Storage Interface)
A standard API that allows storage vendors to write plugins for Kubernetes. CSI drivers let you mount external storage (S3, NFS, cloud disks) as volumes in pods without changing your application code.

**Used in**: [rclone/](rclone/), [s3-pod-identity/](s3-pod-identity/)

### Kustomize
A tool for customizing Kubernetes YAML without templates. Instead of `{{ .Values.x }}` placeholders, you write patches that overlay base manifests. Built into `kubectl` - no extra installation needed.

**Used in**: [kustomize/](kustomize/), all example directories

**Official docs**: <https://kustomize.io/>

### Pod
The smallest deployable unit in Kubernetes. A pod contains one or more containers that share networking and storage. Most apps run as Deployments (which manage pods) rather than bare pods.

### PVC (PersistentVolumeClaim)
A request for storage by a pod. PVCs abstract away the details of where storage comes from - could be local disk, cloud storage, or network-attached storage.

### ServiceAccount
An identity for pods. When a pod needs to access the Kubernetes API or external services (like AWS), it uses a ServiceAccount. Combined with Pod Identity, this enables secure, credential-free access to cloud resources.

## AWS Concepts

### EKS (Elastic Kubernetes Service)
AWS's managed Kubernetes offering. AWS handles the control plane (API server, etcd, scheduler), you manage the workloads.

**Used in**: [eksauto/](eksauto/)

**Official docs**: <https://docs.aws.amazon.com/eks/>

### EKS Auto Mode
A feature where AWS also manages worker nodes - automatic provisioning, scaling, and security patches. You just deploy workloads; AWS picks instance types and handles capacity.

**Used in**: [eksauto/](eksauto/)

### Pod Identity
An EKS feature that lets pods assume IAM roles without storing credentials. The Pod Identity Agent (built into EKS Auto Mode) injects temporary credentials based on the pod's ServiceAccount.

**Used in**: [s3-pod-identity/](s3-pod-identity/), [secrets/](secrets/)

**Official docs**: <https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html>

### Secrets Manager
AWS service for storing and rotating secrets (passwords, API keys, certificates). Applications retrieve secrets at runtime rather than storing them in config files or environment variables.

**Used in**: [secrets/](secrets/)

## DevOps Patterns

### GitOps
A deployment pattern where Git is the single source of truth. You commit desired state to a repo, and a controller (like ArgoCD) automatically syncs the cluster to match. Benefits: audit trail, easy rollbacks, declarative everything.

**Used in**: [argocd/](argocd/)

### Infrastructure as Code (IaC)
Managing infrastructure through configuration files rather than manual processes. Terraform, Pulumi, and CloudFormation are common IaC tools. Benefits: reproducibility, version control, code review for infrastructure changes.

**Used in**: [eksauto/](eksauto/)

### OLAP (Online Analytical Processing)
Workloads focused on complex queries over large datasets - aggregations, reporting, business intelligence. Contrast with OLTP (transactional processing) which handles individual record operations. Columnar storage formats like Parquet are optimized for OLAP.

**Used in**: [ducklake/](ducklake/)

## Tools

### DuckDB
An embedded analytical database (like SQLite, but for analytics). Runs in-process, no server needed. Excellent for querying Parquet files, CSV, and other formats directly.

**Used in**: [ducklake/](ducklake/)

**Official docs**: <https://duckdb.org/>

### Helm
A package manager for Kubernetes. Helm charts bundle related manifests with configurable values. Great for installing third-party software; for your own apps, Kustomize is often simpler.

**Official docs**: <https://helm.sh/>

### Just
A command runner (like Make, but simpler). The `justfile` contains recipes - named commands with dependencies. Run `just` to list all recipes, `just <recipe>` to run one.

**Official docs**: <https://github.com/casey/just>

### k3d
Runs lightweight Kubernetes (k3s) inside Docker containers. Perfect for local development - create/destroy clusters in seconds, no VM overhead.

**Used in**: All local examples

**Official docs**: <https://k3d.io/>

### mise
A polyglot tool version manager (successor to asdf). Manages versions of kubectl, terraform, node, python, and 100+ other tools. Ensures everyone uses the same versions.

**Official docs**: <https://mise.jdx.dev/>

### rclone
"rsync for cloud storage." Syncs files to/from 40+ cloud storage providers. Also provides `rclone serve s3` (expose local storage as S3 API) and CSI drivers for Kubernetes.

**Used in**: [rclone/](rclone/), [s3-pod-identity/](s3-pod-identity/), [ducklake/](ducklake/)

**Official docs**: <https://rclone.org/>

### Terraform
HashiCorp's Infrastructure as Code tool. You declare what resources you want (VPCs, clusters, buckets), Terraform figures out how to create them and tracks state.

**Used in**: [eksauto/](eksauto/)

**Official docs**: <https://www.terraform.io/>

## See Also

- [GETTING_STARTED.md](GETTING_STARTED.md) - First-time setup guide
- [LEARNING_PATH.md](LEARNING_PATH.md) - Suggested order for examples
