variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "training01"
}

variable "kubernetes_version" {
  description = "Pinned EKS Kubernetes version for reproducible training clusters"
  type        = string
  default     = "1.34"
}
