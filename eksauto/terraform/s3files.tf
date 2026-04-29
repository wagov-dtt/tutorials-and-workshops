# AWS S3 Files for EKS POSIX-style mounts via the Amazon EFS CSI driver
# Pattern: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-files-mounting-eks.html

# Roles assumed by the EFS CSI driver via EKS Pod Identity.
resource "aws_iam_role" "efs_csi_controller" {
  name = "eks-efs-csi-controller"

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

resource "aws_iam_role_policy_attachment" "efs_csi_controller_s3files" {
  role       = aws_iam_role.efs_csi_controller.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3FilesCSIDriverPolicy"
}

resource "aws_iam_role" "efs_csi_node" {
  name = "eks-efs-csi-node"

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

resource "aws_iam_role_policy_attachment" "efs_csi_node_s3_read" {
  role       = aws_iam_role.efs_csi_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "efs_csi_node_utils" {
  role       = aws_iam_role.efs_csi_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemsUtils"
}

# Role assumed by the S3 Files service to synchronize the S3-backed file system.
resource "aws_iam_role" "s3files_service" {
  name = "eks-s3files-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3FilesAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3files:${data.aws_region.current.region}:${local.account_id}:file-system/*"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "training"
  }
}

resource "aws_iam_role_policy" "s3files_service" {
  name = "s3files-test-bucket-access"
  role = aws_iam_role.s3files_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = aws_s3_bucket.test.arn
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*"
        ]
        Resource = "${aws_s3_bucket.test.arn}/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "EventBridgeManage"
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]
        Resource = "arn:aws:events:*:*:rule/DO-NOT-DELETE-S3-Files*"
        Condition = {
          StringEquals = {
            "events:ManagedBy" = "elasticfilesystem.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EventBridgeRead"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule"
        ]
        Resource = "arn:aws:events:*:*:rule/*"
      }
    ]
  })
}

resource "aws_security_group" "s3files" {
  name        = "${var.cluster_name}-s3files"
  description = "Allow EKS nodes to mount S3 Files over NFS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "NFS from EKS VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name        = "${var.cluster_name}-s3files"
    Terraform   = "true"
    Environment = "training"
  }
}

resource "aws_s3files_file_system" "test" {
  bucket                = aws_s3_bucket.test.arn
  role_arn              = aws_iam_role.s3files_service.arn
  accept_bucket_warning = true

  tags = {
    Terraform   = "true"
    Environment = "training"
  }

  depends_on = [
    aws_iam_role_policy.s3files_service,
    aws_s3_bucket_versioning.test,
    aws_s3_bucket_server_side_encryption_configuration.test
  ]
}

resource "aws_s3files_mount_target" "test" {
  for_each = toset(module.vpc.private_subnets)

  file_system_id = aws_s3files_file_system.test.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.s3files.id
  ]
}
