# s3-pod-identity/

> Demo of EKS Pod Identity with MySQL backup/restore via rclone. No credentials stored in the cluster.

## Why Pod Identity?

[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) lets pods assume IAM roles without storing AWS credentials anywhere in the cluster. The Pod Identity Agent (built into EKS Auto Mode) injects temporary credentials based on the pod's ServiceAccount.

**Benefits**:
- No static credentials to rotate or leak
- Fine-grained access control per ServiceAccount
- Audit trail in CloudTrail

## Prerequisites

- AWS account with SSO configured (`AWS_PROFILE` and `AWS_REGION` in `.env`)
- EKS cluster created via `just setup-eks`

Terraform pre-creates:
- S3 bucket: `test-<ACCOUNT_ID>`
- IAM role: `eks-s3-test` with S3FullAccess
- Pod Identity associations for `s3-test` and `veloxpack` namespaces

## Quick Start

```bash
just s3-test      # Full demo: sysbench → backup → copy → debug pod
just s3-restore   # Optional: restore backup to sbtest_restored database
just s3-cleanup   # Remove K8s resources (S3 bucket kept)
```

## Architecture

```mermaid
flowchart TB
    subgraph EKS["EKS Cluster"]
        subgraph NS["s3-test namespace"]
            MySQL["MySQL<br/>(Percona 8.0)"]
            Sysbench["sysbench-prepare<br/>Job"]
            Backup["backup-to-s3<br/>Job"]
            Copy["rclone-copy<br/>Job"]
            Restore["restore-from-s3<br/>Job"]
            Debug["debug pod<br/>(S3 CSI mount)"]
            SA["ServiceAccount<br/>s3-access"]
        end
        PIA["Pod Identity Agent"]
    end
    
    subgraph AWS["AWS"]
        IAM["IAM Role<br/>eks-s3-test"]
        S3B1["S3: backup1/"]
        S3B2["S3: backup2/"]
    end
    
    Sysbench -->|"prepare test data"| MySQL
    MySQL -->|"mysqlsh dump"| Backup
    Backup -->|"rclone upload"| S3B1
    S3B1 -->|"rclone copy"| Copy
    Copy -->|"server-side copy"| S3B2
    S3B2 -->|"mysqlsh load"| Restore
    Restore -->|"restore to sbtest_restored"| MySQL
    Debug -->|"CSI mount"| S3B2
    
    SA -.->|"binds to"| PIA
    PIA -.->|"assumes"| IAM
    IAM -.->|"S3FullAccess"| S3B1
    IAM -.->|"S3FullAccess"| S3B2
```

## What's Here

| File | Purpose |
|------|---------|
| [base/namespace.yaml](base/namespace.yaml) | Namespace and ServiceAccount |
| [base/rclone.yaml](base/rclone.yaml) | Shared rclone config (env vars, CSI secret, StorageClass) |
| [base/mysql.yaml](base/mysql.yaml) | MySQL deployment and sysbench data prep |
| [base/debug.yaml](base/debug.yaml) | Debug pod with S3 CSI mount |
| [jobs/backup.yaml](jobs/backup.yaml) | mysqlsh dump → S3 backup1/ |
| [jobs/copy.yaml](jobs/copy.yaml) | rclone server-side copy backup1/ → backup2/ |
| [jobs/restore.yaml](jobs/restore.yaml) | S3 backup2/ → mysqlsh load |

## Learning Goals

- **EKS Pod Identity**: How pods assume IAM roles without static credentials
- **mysqlsh for backups**: Using MySQL Shell's `util.dumpSchemas()` and `util.loadDump()`
- **rclone server-side copy**: Copying between S3 prefixes without downloading locally
- **CSI S3 mounts**: Mounting S3 buckets into pods for debugging and inspection

## Debugging

### Interactive Cluster UI

```bash
just -c k9s  # Opens k9s with AWS credentials loaded
```

### S3 Bucket Inspection

```bash
just -c 'aws s3 ls s3://test-$(just _account)/'         # List bucket root
just -c 'aws s3 ls s3://test-$(just _account)/backup1/' # List backup contents
```

### Debug Pod

```bash
kubectl exec -it debug -n s3-test -- sh
ls /mnt/s3  # S3 bucket contents via rclone CSI
```

Uses the [veloxpack rclone CSI driver](https://github.com/veloxpack/csi-driver-rclone) to mount S3 as a filesystem.

### CSI Driver Logs

If S3 mounts fail, check the CSI driver logs:

```bash
kubectl logs -n veloxpack -l app=csi-rclone-node --tail=50
```

Common issue: 403 errors on `ListBuckets` indicate the Pod Identity IAM role is missing `s3:ListAllMyBuckets` permission.

## Key Patterns

- **initContainer + main container**: [backup.yaml](jobs/backup.yaml) uses an initContainer for mysqlsh dump, main container for rclone upload
- **Server-side copy**: [copy.yaml](jobs/copy.yaml) copies between S3 prefixes without downloading locally
- **Schema rename on restore**: [restore.yaml](jobs/restore.yaml) uses `util.loadDump()` with the `schema` option to restore to a different database name
- **Pod Identity auth**: All jobs use `serviceAccountName: s3-access` bound to an IAM role via Terraform's `aws_eks_pod_identity_association`

## See Also

- [LEARNING_PATH.md](../LEARNING_PATH.md#22-s3-pod-identity) - Step-by-step walkthrough
- [GLOSSARY.md](../GLOSSARY.md#pod-identity) - Pod Identity definition
- [rclone/](../rclone/) - rclone CSI examples on local k3d
- [eksauto/](../eksauto/) - EKS cluster configuration and cost info
- [EKS Pod Identity docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) - Official AWS documentation
