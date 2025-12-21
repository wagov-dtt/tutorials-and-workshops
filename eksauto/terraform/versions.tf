terraform {
  required_version = ">= 1.10"

  # S3 backend with native locking (no DynamoDB needed)
  # Bucket created automatically by `just setup-eks`
  backend "s3" {
    key          = "eksauto/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  # Uses AWS_PROFILE and AWS_REGION from environment
}
