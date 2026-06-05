# Pod Identity Associations
# Pre-created for examples that need AWS API access from pods

# s3-test namespace - used by s3-pod-identity Helm chart example
resource "aws_eks_pod_identity_association" "s3_test" {
  cluster_name    = module.eks.cluster_name
  namespace       = "s3-test"
  service_account = "s3-access"
  role_arn        = aws_iam_role.eks_s3_test.arn

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

# kube-system namespace - used by the EFS CSI driver for AWS S3 Files mounts
resource "aws_eks_pod_identity_association" "efs_csi_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-controller-sa"
  role_arn        = aws_iam_role.efs_csi_controller.arn

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

resource "aws_eks_pod_identity_association" "efs_csi_node" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-node-sa"
  role_arn        = aws_iam_role.efs_csi_node.arn

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

# external-secrets namespace - used by External Secrets Operator
resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eks_secrets_manager.arn

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

# observability namespace - used by the optional OTel collector CloudWatch/X-Ray fan-out
resource "aws_eks_pod_identity_association" "observability_collector" {
  cluster_name    = module.eks.cluster_name
  namespace       = "observability"
  service_account = "otel-collector"
  role_arn        = aws_iam_role.eks_observability_collector.arn

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}
