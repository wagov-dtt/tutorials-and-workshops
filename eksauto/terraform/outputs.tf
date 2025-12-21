output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "s3_bucket" {
  description = "S3 bucket for backups"
  value       = aws_s3_bucket.test.id
}

output "s3_role_arn" {
  description = "IAM role ARN for S3 access"
  value       = aws_iam_role.eks_s3_test.arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_version" {
  description = "EKS cluster Kubernetes version"
  value       = local.eks_version
}

output "secrets_manager_role_arn" {
  description = "IAM role ARN for Secrets Manager access"
  value       = aws_iam_role.eks_secrets_manager.arn
}

output "example_secret_arn" {
  description = "ARN of the example secret in Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "argocd_enabled" {
  description = "Whether ArgoCD capability is enabled"
  value       = var.enable_argocd
}

output "argocd_ui_command" {
  description = "Command to get ArgoCD UI URL (if enabled)"
  value       = var.enable_argocd ? "aws eks describe-capability --cluster-name ${var.cluster_name} --capability-name argocd --query 'capability.argoCdDetail.webServerEndpoint' --output text" : "ArgoCD not enabled - run with enable_argocd=false was used"
}
