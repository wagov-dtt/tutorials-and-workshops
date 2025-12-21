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

resource "aws_iam_role_policy_attachment" "eks_s3_test" {
  role       = aws_iam_role.eks_s3_test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# S3 bucket for backups (versioning for recovery)
resource "aws_s3_bucket" "test" {
  bucket = "test-${local.account_id}"

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

# Policy for Secrets Manager read access
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
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
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
