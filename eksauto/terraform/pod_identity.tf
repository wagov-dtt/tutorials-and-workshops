# Pod Identity Associations
# Pre-created for all examples that need S3 access

# s3-test namespace - used by kustomize-s3-pod-identity example
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

# veloxpack namespace - used by rclone CSI driver
resource "aws_eks_pod_identity_association" "veloxpack_csi" {
  cluster_name    = module.eks.cluster_name
  namespace       = "veloxpack"
  service_account = "csi-rclone-node-sa"
  role_arn        = aws_iam_role.eks_s3_test.arn

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
