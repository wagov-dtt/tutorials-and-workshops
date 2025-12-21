# EKS Capability for ArgoCD (fully managed)
# Enabled by default - auto-discovers Identity Center instance
# If Identity Center isn't configured, provides clear guidance

# ArgoCD Capability IAM Role
resource "aws_iam_role" "argocd_capability" {
  count = var.enable_argocd ? 1 : 0
  name  = "eks-argocd-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

# Note: ArgoCD capability is created via just recipes (argocd-create, argocd-delete)
# This keeps the IAM role in Terraform (real infrastructure) while the capability
# itself is managed imperatively via AWS CLI (simpler, easier to debug)
