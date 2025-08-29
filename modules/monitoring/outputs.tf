output "amp_workspace_id" {
  description = "AMP workspace ID"
  value       = aws_prometheus_workspace.main.id
}

output "amp_workspace_arn" {
  description = "AMP workspace ARN"
  value       = aws_prometheus_workspace.main.arn
}

output "amg_workspace_id" {
  description = "AMG workspace ID"
  value       = "disabled" # Grafana disabled due to SSO requirement
}

output "amg_workspace_arn" {
  description = "AMG workspace ARN"
  value       = "disabled" # Grafana disabled due to SSO requirement
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.main.endpoint
}

output "opensearch_domain_arn" {
  description = "OpenSearch domain ARN"
  value       = aws_opensearch_domain.main.arn
}

output "grafana_endpoint" {
  description = "Grafana endpoint"
  value       = "disabled" # Grafana disabled due to SSO requirement
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  value       = aws_opensearch_domain.main.endpoint
}
