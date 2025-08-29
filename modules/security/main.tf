# KMS Module - Replaces individual KMS key resources
module "kms_keys" {
  source = "../kms"
  
  name_prefix = var.name
  
  key_configs = {
    ebs = {
      description = "EBS volume encryption"
      service    = "ec2"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    efs = {
      description = "EFS file system encryption"
      service    = "elasticfilesystem"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    rds = {
      description = "RDS database encryption"
      service    = "rds"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    s3 = {
      description = "S3 bucket encryption"
      service    = "s3"
      key_usage  = "ENCRYPT_DECRYPT"
    }
    opensearch = {
      description = "OpenSearch domain encryption"
      service    = "es"
      key_usage  = "ENCRYPT_DECRYPT"
    }
  }
  
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = var.tags
}

# IAM Role for EKS Service Account (IRSA)
resource "aws_iam_role" "eks_service_account" {
  name = "${var.name}-eks-service-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/https:///", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins" {
  name = "${var.name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Jenkins ECR access
resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${var.name}-jenkins-ecr-policy"
  description = "Policy for Jenkins to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Jenkins EKS access
resource "aws_iam_policy" "jenkins_eks" {
  name        = "${var.name}-jenkins-eks-policy"
  description = "Policy for Jenkins to access EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_eks.arn
}


