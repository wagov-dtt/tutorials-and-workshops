# eksauto/

EKS Auto Mode cluster managed by Terraform.

## ⚠️ Cost Warning

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

## What Terraform Creates

| Resource | Purpose |
|----------|---------|
| S3 bucket `tfstate-<account>` | Terraform state with native S3 locking (auto-created) |
| VPC + subnets | Network infrastructure (3 AZs) |
| EKS cluster | Auto Mode enabled, latest K8s version (auto-detected) |
| EKS addons | snapshot-controller, CloudWatch Observability, EFS CSI |
| IAM role `eks-s3-test` | S3 access for Pod Identity |
| IAM role `eks-secrets-manager` | Secrets Manager access for External Secrets Operator |
| S3 bucket `test-<account>` | Backup storage for examples |
| Secrets Manager `training/db-credentials` | Example secret for ESO demo |
| Pod Identity associations | Pre-created for s3-test, veloxpack, external-secrets namespaces |

## Terraform Files

| File | Purpose |
|------|---------|
| [terraform/main.tf](terraform/main.tf) | VPC + EKS cluster + addons |
| [terraform/iam.tf](terraform/iam.tf) | IAM role + S3 bucket |
| [terraform/pod_identity.tf](terraform/pod_identity.tf) | Pod Identity associations |
| [terraform/outputs.tf](terraform/outputs.tf) | Cluster info + kubectl command |

## ArgoCD Capability

[EKS Capability for ArgoCD](https://docs.aws.amazon.com/eks/latest/userguide/argocd-comparison.html) is **enabled by default**. Terraform auto-discovers your Identity Center instance.

If Identity Center isn't configured, Terraform fails with clear guidance - either configure it or disable ArgoCD:

```bash
terraform apply -var="enable_argocd=false"
```

To add yourself as ArgoCD admin:

```bash
# Get your user ID
STORE_ID=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)
aws identitystore list-users --identity-store-id $STORE_ID

# Apply with admin user
terraform apply -var="idc_admin_user_id=YOUR_USER_ID"
```

## Observability

The cluster includes the `amazon-cloudwatch-observability` addon which provides:

- **Container Insights**: CPU, memory, disk, network metrics per pod/node
- **CloudWatch Logs**: Container logs automatically shipped to CloudWatch
- **ADOT collector**: OpenTelemetry-based metrics and traces collection

**Why use the managed addon?** Zero configuration, auto-updates, integrates with existing CloudWatch dashboards and alarms. No need to deploy Prometheus/Grafana for basic observability.

View metrics in AWS Console → CloudWatch → Container Insights → Performance Monitoring.

## Learning Goals

- **Terraform for EKS**: Declarative infrastructure with state management
- **S3 backend with native locking**: No DynamoDB needed (Terraform 1.10+)
- **EKS Auto Mode**: AWS manages node provisioning, scaling, security patches
- **Pod Identity**: Pre-created associations linking ServiceAccounts to IAM roles
- **terraform-aws-modules**: Using community modules for VPC and EKS
- **Managed observability**: CloudWatch Container Insights vs self-hosted Prometheus

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
