data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# Get latest EKS version
data "aws_eks_cluster_versions" "available" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  azs         = slice(data.aws_availability_zones.available.names, 0, 3)
  eks_version = data.aws_eks_cluster_versions.available.cluster_versions[0].cluster_version
}

# VPC for EKS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

# EKS Cluster with Auto Mode
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = local.eks_version

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Auto Mode
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  # CloudWatch logging
  cluster_enabled_log_types = ["audit", "authenticator"]

  # Access managed via `just eks-access` (SSO roles can't be imported to TF state)

  # Addons - all use latest versions
  # Note: We use rclone CSI for S3 mounts, not EFS CSI
  cluster_addons = {
    snapshot-controller             = { most_recent = true }
    amazon-cloudwatch-observability = { most_recent = true }
  }

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}
