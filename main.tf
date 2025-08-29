terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }


}

# Data source to get bootstrap outputs
data "terraform_remote_state" "bootstrap" {
  backend = "local"
  config = {
    path = "${path.module}/bootstrap/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.bootstrap.outputs.aws_region
  
  default_tags {
    tags = {
      Project     = data.terraform_remote_state.bootstrap.outputs.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "core-infrastructure"
    }
  }
}

# Provider for us-east-1 (required for CloudFront WAF)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = data.terraform_remote_state.bootstrap.outputs.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "core-infrastructure"
    }
  }
}

# Local values for common configuration
locals {
  project_name = data.terraform_remote_state.bootstrap.outputs.project_name
  environment  = var.environment
  region      = data.terraform_remote_state.bootstrap.outputs.aws_region
  
  # Common tags
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "core-infrastructure"
  }
  
  # VPC configuration
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    azs        = ["${local.region}a", "${local.region}b", "${local.region}c"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
    data_subnets    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  }
}
