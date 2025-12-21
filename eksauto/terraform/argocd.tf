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

# Create ArgoCD capability - auto-discovers Identity Center
resource "null_resource" "argocd_capability" {
  count      = var.enable_argocd ? 1 : 0
  depends_on = [module.eks, aws_iam_role.argocd_capability]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      echo "=== Setting up ArgoCD EKS Capability ==="
      
      # Auto-discover Identity Center instance
      echo "Checking for AWS Identity Center..."
      IDC_INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null || echo "")
      
      if [ -z "$IDC_INSTANCE_ARN" ] || [ "$IDC_INSTANCE_ARN" = "None" ]; then
        echo ""
        echo "ERROR: AWS Identity Center is not configured in this account."
        echo ""
        echo "To use ArgoCD, either:"
        echo "  1. Configure Identity Center: https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html"
        echo "  2. Or disable ArgoCD: terraform apply -var='enable_argocd=false'"
        echo ""
        exit 1
      fi
      
      echo "Found Identity Center: $IDC_INSTANCE_ARN"
      
      # Check for admin user ID
      ADMIN_USER_ID="${var.idc_admin_user_id}"
      if [ -z "$ADMIN_USER_ID" ]; then
        echo ""
        echo "NOTE: No admin user specified. ArgoCD will be created without RBAC mappings."
        echo "To add an admin user later, get your user ID with:"
        echo ""
        echo "  STORE_ID=\$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)"
        echo "  aws identitystore list-users --identity-store-id \$STORE_ID"
        echo ""
        echo "Then update the capability in the AWS console or recreate with:"
        echo "  terraform apply -var='idc_admin_user_id=YOUR_USER_ID'"
        echo ""
        
        # Create without RBAC mappings - user can add via console
        aws eks create-capability \
          --region ${data.aws_region.current.name} \
          --cluster-name ${module.eks.cluster_name} \
          --capability-name argocd \
          --type ARGOCD \
          --role-arn ${aws_iam_role.argocd_capability[0].arn} \
          --configuration "{
            \"argoCd\": {
              \"awsIdc\": {
                \"idcInstanceArn\": \"$IDC_INSTANCE_ARN\",
                \"idcRegion\": \"${data.aws_region.current.name}\"
              }
            }
          }"
      else
        echo "Creating ArgoCD capability with admin user: $ADMIN_USER_ID"
        
        aws eks create-capability \
          --region ${data.aws_region.current.name} \
          --cluster-name ${module.eks.cluster_name} \
          --capability-name argocd \
          --type ARGOCD \
          --role-arn ${aws_iam_role.argocd_capability[0].arn} \
          --configuration "{
            \"argoCd\": {
              \"awsIdc\": {
                \"idcInstanceArn\": \"$IDC_INSTANCE_ARN\",
                \"idcRegion\": \"${data.aws_region.current.name}\"
              },
              \"rbacRoleMappings\": [{
                \"role\": \"ADMIN\",
                \"identities\": [{
                  \"id\": \"$ADMIN_USER_ID\",
                  \"type\": \"SSO_USER\"
                }]
              }]
            }
          }"
      fi
      
      echo ""
      echo "Waiting for ArgoCD capability to become ACTIVE..."
      for i in {1..30}; do
        STATUS=$(aws eks describe-capability \
          --cluster-name ${module.eks.cluster_name} \
          --capability-name argocd \
          --region ${data.aws_region.current.name} \
          --query 'capability.status' --output text 2>/dev/null || echo "CREATING")
        echo "  Status: $STATUS"
        if [ "$STATUS" = "ACTIVE" ]; then
          echo ""
          echo "=== ArgoCD capability is ACTIVE ==="
          ARGOCD_URL=$(aws eks describe-capability \
            --cluster-name ${module.eks.cluster_name} \
            --capability-name argocd \
            --region ${data.aws_region.current.name} \
            --query 'capability.argoCdDetail.webServerEndpoint' --output text)
          echo "ArgoCD UI: $ARGOCD_URL"
          echo "Login with your Identity Center credentials"
          exit 0
        fi
        sleep 10
      done
      echo "Timeout waiting for ArgoCD capability - check AWS console"
      exit 1
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws eks delete-capability --cluster-name ${self.triggers.cluster_name} --capability-name argocd --delete-propagation-policy DELETE --region ${self.triggers.region} || true"
  }

  triggers = {
    cluster_name = module.eks.cluster_name
    region       = data.aws_region.current.name
  }
}

# Data source for current region
data "aws_region" "current" {}
