# IAM Role for S3 access (used by Pod Identity)
resource "aws_iam_role" "eks_s3_test" {
  name = "eks-s3-test"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
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

# Scoped S3 policy for test bucket only
resource "aws_iam_role_policy" "eks_s3_test" {
  name = "s3-test-bucket-access"
  role = aws_iam_role.eks_s3_test.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.test.arn,
          "${aws_s3_bucket.test.arn}/*"
        ]
      }
    ]
  })
}

# S3 bucket for backups (versioned, force_destroy for easy cleanup)
resource "aws_s3_bucket" "test" {
  bucket        = "test-${local.account_id}"
  force_destroy = true

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

resource "aws_s3_bucket_versioning" "test" {
  bucket = aws_s3_bucket.test.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test" {
  bucket = aws_s3_bucket.test.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for Secrets Manager access (used by External Secrets Operator)
resource "aws_iam_role" "eks_secrets_manager" {
  name = "eks-secrets-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
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

# Policy for Secrets Manager read access (scoped to training secrets)
resource "aws_iam_role_policy" "secrets_manager_read" {
  name = "secrets-manager-read"
  role = aws_iam_role.eks_secrets_manager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:${local.account_id}:secret:training/*"
      },
      {
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })
}

# Example secret for External Secrets demo
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "training/db-credentials"
  recovery_window_in_days = 0 # Allow immediate deletion for training

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = "training-password-change-me"
  })
}
