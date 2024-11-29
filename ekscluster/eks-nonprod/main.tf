terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.78.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

resource "aws_s3_bucket" "eks_testcluster01_nonprod" {
  bucket = "ekstestcluster01nonprod"

  tags = {
    "Owner" = "Tutorials and Workshops"
    "Repository" = "https://github.com/wagov-dtt/tutorials-and-workshops"
  }
}

# Create an IAM role that can access the specific S3 bucket
resource "aws_iam_role" "s3_access_role" {
  name = "role-s3-access-ekstestcluster01nonprod"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
})
}

# Create an IAM policy that grants access to the specific S3 bucket
resource "aws_iam_policy" "s3_bucket_access_policy" {
  name        = "policy-s3-bucket-access-ekstestcluster01nonprod"
  description = "Policy to allow full access to a specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
        ]
        Resource = [
          aws_s3_bucket.eks_testcluster01_nonprod.arn,
          "${aws_s3_bucket.eks_testcluster01_nonprod.arn}/*",  # Allow access to all objects in the bucket
        ]
      },
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = aws_iam_policy.s3_bucket_access_policy.arn
  role       = aws_iam_role.s3_access_role.name
}

# Output the ARN of the S3 bucket
output "aws_iam_role" {
  value = aws_iam_role.s3_access_role.arn
}