# eksauto/

EKS Auto Mode cluster managed by Terraform. AWS manages node provisioning, scaling, and security patches.

This is an AWS lab. Run `just aws-preflight` before creating resources.

## Cost warning

This creates paid AWS resources.

| Component | Typical cost driver |
|-----------|---------------------|
| EKS control plane | About $0.10/hour |
| EKS Auto Mode | Auto Mode fee plus EC2 workload capacity |
| EC2 capacity | Varies by workload and chosen instance types |
| CloudWatch logs/metrics | Ingestion and retention volume |
| NAT/data transfer/S3/EFS-related services | Usage-dependent |

Expect an idle training cluster to cost roughly the EKS control plane plus any minimum workload capacity. Always destroy the lab when done:

```bash
just eksauto/destroy-eks
```

## Quick start

```bash
just eksauto/setup-eks      # Create cluster via Terraform
just eksauto/smoke          # Check cluster access
just eksauto/deploy         # Deploy database Helm chart
# ... train or inspect ...
just eksauto/destroy-eks    # Destroy paid resources
```

## Full validation with inspection pause

`just validate-aws` creates the cluster, runs tests, pauses for manual inspection, then destroys resources.

```bash
just validate-aws
```

During the pause, open another terminal and use `just -c` so AWS credentials are loaded consistently:

```bash
just -c k9s
just -c 'kubectl get pods -A'
just -c 'aws s3 ls s3://test-$(just _account)/'
```

Press Enter in the original terminal to continue destruction, or Ctrl+C to keep resources running temporarily.

## What Terraform creates

| Resource | Purpose |
|----------|---------|
| S3 bucket `tfstate-<account>` | Terraform state with native S3 locking |
| VPC + subnets | Network infrastructure across 3 AZs |
| EKS cluster | Auto Mode cluster |
| EKS add-ons | Snapshot controller, CloudWatch Observability, EFS CSI driver for AWS S3 Files |
| IAM role `eks-s3-test` | S3 access for Pod Identity demos |
| IAM roles `eks-efs-csi-*` | EFS CSI access for AWS S3 Files mounts |
| IAM role `eks-s3files-service` | S3 Files service access to sync the test bucket |
| IAM role `eks-secrets-manager` | Secrets Manager access for External Secrets Operator |
| IAM role `eks-observability-collector` | CloudWatch Logs and X-Ray write access for optional observability collector |
| S3 bucket `test-<account>` | Backup storage for examples |
| S3 Files file system + mount targets | POSIX-style S3 mount for EKS examples |
| Secrets Manager `training/db-credentials` | Example secret for the ESO demo |
| Pod Identity associations | Associations for `s3-test`, EFS CSI, External Secrets, and observability namespaces |

## Terraform files

| File | Purpose |
|------|---------|
| `terraform/main.tf` | VPC, EKS cluster, and add-ons |
| `terraform/iam.tf` | IAM roles and S3 bucket resources |
| `terraform/s3files.tf` | AWS S3 Files file system, mount targets, and CSI IAM roles |
| `terraform/pod_identity.tf` | Pod Identity associations |
| `terraform/outputs.tf` | Cluster info and kubectl command |

## What you learn

- Terraform-managed EKS infrastructure
- S3 backend with native locking in Terraform 1.10+
- EKS Auto Mode operations
- EKS Pod Identity and ServiceAccount-to-IAM binding
- AWS-managed observability with CloudWatch Container Insights
- How to render Helm charts before applying them to a paid cluster

## Helm deployment model

Kubernetes examples are repo-owned Helm charts. Deploy them directly from CI or reconcile them from an orchestration cluster. See [../argocd/README.md](../argocd/README.md).

## Observability

The cluster includes the `amazon-cloudwatch-observability` add-on:

- Container Insights for pod/node metrics
- CloudWatch Logs for container logs
- ADOT/OpenTelemetry-based collection

View metrics in AWS Console → CloudWatch → Container Insights → Performance Monitoring.

If you also want a cluster-local UI, keep CloudWatch enabled and deploy the optional Victoria*/Grafana stack as a short-retention hot cache:

```bash
just observability/deploy-eksauto-cloudwatch
```

That recipe fans app OTLP out to in-cluster Victoria* and AWS-managed backends. See [../observability/README.md](../observability/README.md#storage-and-eks-auto-mode).

## Manual Terraform commands

Use the `just` recipes for normal training. If you need Terraform directly:

```bash
cd eksauto/terraform
terraform init
terraform plan
terraform apply
terraform destroy
```

## Cleanup troubleshooting

```bash
just eksauto/destroy-eks
```

If destroy fails:

1. Delete any remaining `LoadBalancer` services.
2. Delete stuck PVCs if they block storage cleanup.
3. Retry `just eksauto/destroy-eks`.

## References

- [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)
- [AWS S3 Files on EKS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files-mounting-eks.html)
- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
