variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "training01"
}

# ArgoCD Capability (enabled by default)
# Requires AWS Identity Center - if not configured, Terraform will fail with guidance
variable "enable_argocd" {
  description = "Enable EKS Capability for ArgoCD (requires Identity Center)"
  type        = bool
  default     = true
}

variable "idc_admin_user_id" {
  description = "Identity Center user ID for ArgoCD admin. Get with: aws identitystore list-users --identity-store-id $(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)"
  type        = string
  default     = ""
}
