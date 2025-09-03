# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  name                 = local.project_name
  vpc_cidr            = local.vpc_config.cidr_block
  availability_zones  = local.vpc_config.azs
  public_subnets      = local.vpc_config.public_subnets
  private_subnets     = local.vpc_config.private_subnets
  data_subnets        = local.vpc_config.data_subnets
  allowed_ssh_cidrs   = var.allowed_ssh_cidrs
  tags                = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  name                = local.project_name
  tags                = local.common_tags
  oidc_provider_arn  = module.eks.oidc_provider_arn
  namespace           = "jenkins"
  service_account_name = "jenkins"
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name                    = var.cluster_name
  kubernetes_version             = "1.28"
  subnet_ids                     = module.vpc.private_subnet_ids
  vpc_id                         = module.vpc.vpc_id
  kms_key_arn                    = module.security.kms_key_arns.ebs
  node_group_desired_size        = 2
  node_group_max_size            = 4
  node_group_min_size            = 1
  node_group_instance_types      = ["t3.medium"]
  tags                           = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  cluster_name           = "${local.project_name}-jenkins-agents"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  task_execution_role_arn = module.security.jenkins_role_arn
  tags                   = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  repository_names      = ["jenkins-controller", "jenkins-agent", "application"]
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  jenkins_role_arn     = module.security.jenkins_role_arn
  tags                 = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  name        = local.project_name
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.data_subnet_ids
  environment = local.environment
  allowed_security_group_ids = [module.vpc.security_group_ids.eks, module.vpc.security_group_ids.ecs]
  tags        = local.common_tags
}

# Self-signed certificate for ALB (temporary - replace with ACM certificate in production)
resource "tls_self_signed_cert" "alb" {
  private_key_pem = tls_private_key.alb.private_key_pem

  subject {
    common_name  = "*.${var.domain_name}"
    organization = "Core Services Infrastructure"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "alb" {
  algorithm = "RSA"
  rsa_bits = 2048
}

# Import the certificate to AWS
resource "aws_acm_certificate" "alb" {
  private_key      = tls_private_key.alb.private_key_pem
  certificate_body = tls_self_signed_cert.alb.cert_pem

  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"
  
  name             = local.project_name
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  target_group_arns = [module.eks.cluster_arn] # Placeholder
  certificate_arn  = aws_acm_certificate.alb.arn
  tags             = local.common_tags
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"
  
  name                = local.project_name
  origin_domain_names = [
    module.monitoring.opensearch_endpoint
  ]
  waf_web_acl_arn = aws_wafv2_web_acl.public_dashboards.arn
  tags            = local.common_tags
}



# WAF for public dashboards (must be in us-east-1 for CloudFront)
resource "aws_wafv2_web_acl" "public_dashboards" {
  provider    = aws.us-east-1
  name        = "${local.project_name}-public-dashboards-waf"
  description = "WAF for public dashboards"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "PublicDashboardsWAFMetric"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}





# Additional variables
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed SSH access to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Outputs for other modules to consume
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}
