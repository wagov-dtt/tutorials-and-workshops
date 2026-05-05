---
title: "EKS Auto Mode"
description: "Terraform-managed EKS Auto Mode cluster."
weight: 50
icon: "cloud"
---

> EKS Auto Mode cluster managed by Terraform. AWS handles node provisioning, scaling, and security patches.

## Cost Warning

**This creates AWS resources that cost money.**

| Component | Estimated Cost |
|-----------|---------------|
| EKS control plane | ~$73/month ($0.10/hr) |
| EKS Auto Mode fee | ~12% on top of EC2 costs |
| EC2 instances | Varies by workload (Auto Mode picks instance types) |
| CloudWatch logs | ~$0.50/GB ingested |

**Minimum idle cluster**: ~$80-100/month (control plane + minimal nodes)

**Always destroy when done:**

```bash
just destroy-eks
```

## Quick Start

```bash
just setup-eks      # Create cluster via Terraform
just deploy         # Deploy kustomize manifests
# ... do your training ...
just destroy-eks    # IMPORTANT: destroys everything
```

## Full Validation with Inspection Pause

The `validate-aws` recipe runs the full test suite and pauses before destruction so you can manually inspect resources:

```bash
just validate-aws   # Creates cluster, runs tests, pauses for inspection, then destroys
```

During the pause, open another terminal and use `just -c` to run commands with AWS credentials loaded:

```bash
just -c k9s                                           # Interactive cluster UI
just -c 'aws s3 ls s3://test-$(just _account)/'       # List S3 bucket
just -c 'kubectl get pods -A'                         # List all pods
```

Press Enter to continue with destruction, or Ctrl+C to abort and keep resources running.

## What Terraform Creates

| Resource | Purpose |
|----------|---------|
| S3 bucket `tfstate-<account>` | Terraform state with native S3 locking (auto-created) |
| VPC + subnets | Network infrastructure (3 AZs) |
| EKS cluster | Auto Mode enabled, latest K8s version (auto-detected) |
| EKS addons | snapshot-controller, CloudWatch Observability, EFS CSI driver for AWS S3 Files |
| IAM role `eks-s3-test` | S3 access for Pod Identity |
| IAM roles `eks-efs-csi-*` | EFS CSI access for AWS S3 Files mounts |
| IAM role `eks-s3files-service` | S3 Files service access to synchronize the test bucket |
| IAM role `eks-secrets-manager` | Secrets Manager access for External Secrets Operator |
| S3 bucket `test-<account>` | Backup storage for examples |
| S3 Files file system + mount targets | POSIX-style S3 mount for EKS examples |
| Secrets Manager `training/db-credentials` | Example secret for ESO demo |
| Pod Identity associations | Pre-created for s3-test, kube-system EFS CSI, external-secrets namespaces |

## Terraform Files

| File | Purpose |
|------|---------|
| [terraform/main.tf](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/eksauto/terraform/main.tf) | VPC, EKS cluster, and addons |
| [terraform/iam.tf](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/eksauto/terraform/iam.tf) | IAM role and S3 bucket |
| [terraform/s3files.tf](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/eksauto/terraform/s3files.tf) | AWS S3 Files file system, mount targets, and CSI IAM roles |
| [terraform/pod_identity.tf](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/eksauto/terraform/pod_identity.tf) | Pod Identity associations |
| [terraform/outputs.tf](https://github.com/wagov-dtt/tutorials-and-workshops/blob/main/eksauto/terraform/outputs.tf) | Cluster info and kubectl command |

## Learning Goals

- **Terraform for EKS**: Declarative infrastructure with state management
- **S3 backend with native locking**: No DynamoDB needed (Terraform 1.10+)
- **EKS Auto Mode**: AWS manages node provisioning, scaling, and security patches
- **Pod Identity**: Pre-created associations linking ServiceAccounts to IAM roles
- **terraform-aws-modules**: Using community modules for VPC and EKS
- **Managed observability**: CloudWatch Container Insights vs self-hosted Prometheus

## ArgoCD (Optional)

ArgoCD EKS Capability requires AWS Identity Center and is disabled by default. See [argocd/README.md](argocd.md) for setup if needed.

## Observability

The cluster includes the `amazon-cloudwatch-observability` addon which provides:

- **Container Insights**: CPU, memory, disk, and network metrics per pod/node
- **CloudWatch Logs**: Container logs automatically shipped to CloudWatch
- **ADOT collector**: OpenTelemetry-based metrics and traces collection

**Why use the managed addon?** Zero configuration, auto-updates, and integration with existing CloudWatch dashboards and alarms. No need to deploy Prometheus/Grafana for basic observability.

View metrics in AWS Console → CloudWatch → Container Insights → Performance Monitoring.

## Manual Terraform Commands

To run Terraform directly:

```bash
cd eksauto/terraform
terraform init
terraform plan
terraform apply
terraform destroy
```

## Cleanup

Terraform handles all cleanup:

```bash
just destroy-eks   # Destroys VPC, EKS, IAM, S3, and all associated resources
```

If destroy fails, check for:
- LoadBalancer services still running (delete them first)
- Stuck PVCs (delete them first)
- Then retry `just destroy-eks`

## See Also

- [LEARNING_PATH.md](../learning-path.md#21-create-an-eks-cluster) - Step-by-step walkthrough
- [GLOSSARY.md](../glossary.md) - Definitions (EKS, Auto Mode, Terraform, Pod Identity)
- [s3-pod-identity/](s3-pod-identity.md) - Pod Identity examples
- [secrets/](secrets.md) - External Secrets examples
- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks) - EKS module docs
