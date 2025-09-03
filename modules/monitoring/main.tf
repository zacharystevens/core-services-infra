terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Amazon Managed Prometheus (AMP) Workspace
resource "aws_prometheus_workspace" "main" {
  alias = "${var.name}-amp-workspace"

  tags = var.tags
}

# Amazon Managed Grafana (AMG) Workspace - Disabled due to SSO requirement
# Uncomment and configure SSO in your AWS account to enable this
# resource "aws_grafana_workspace" "main" {
#   account_access_type      = "CURRENT_ACCOUNT"
#   authentication_providers = ["AWS_SSO"]
#   permission_type          = "SERVICE_MANAGED"
#   role_arn                 = aws_iam_role.grafana_service_role.arn
#   stack_set_name           = "AWSManagedGrafana-${var.environment}"
#
#   tags = var.tags
# }

# IAM Role for Grafana
resource "aws_iam_role" "grafana_service_role" {
  name = "${var.name}-grafana-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach Grafana policies
resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.name}-os"
  engine_version = "OpenSearch_2.5"

  cluster_config {
    instance_type            = "t3.small.search"
    instance_count          = 1
    zone_awareness_enabled  = false
    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }



  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids = [var.subnet_ids[0]] # Use only the first subnet for single-AZ deployment
    security_group_ids = [aws_security_group.opensearch.id]
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch.result
    }
  }

  tags = var.tags
}

# Security Group for OpenSearch
resource "aws_security_group" "opensearch" {
  name_prefix = "${var.name}-opensearch-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-opensearch-sg"
  })
}

# Random password for OpenSearch admin
resource "random_password" "opensearch" {
  length  = 16
  special = true
}

# CloudWatch Log Group for OpenSearch
resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${var.name}"
  retention_in_days = 30

  tags = var.tags
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.name}"
  retention_in_days = 30

  tags = var.tags
}

# CloudWatch Log Group for Security Logs
resource "aws_cloudwatch_log_group" "security" {
  name              = "/aws/security/${var.name}"
  retention_in_days = 90

  tags = var.tags
}
