output "repository_urls" {
  description = "Map of repository names to repository URLs"
  value = {
    for name, repo in aws_ecr_repository.main : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to repository ARNs"
  value = {
    for name, repo in aws_ecr_repository.main : name => repo.arn
  }
}
