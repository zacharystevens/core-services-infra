# Simple WAF Module - Following KISS Principle
# This module creates a basic WAF with essential security rules

# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name}-waf"
  description = var.description
  scope       = var.scope

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Visibility configuration
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}WAFMetric"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
