output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "List of data subnet IDs"
  value       = aws_subnet.data[*].id
}

output "nat_gateway_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    alb         = aws_security_group.alb.id
    eks         = aws_security_group.eks.id
    ecs         = aws_security_group.ecs.id
    rds         = aws_security_group.rds.id
    opensearch  = aws_security_group.opensearch.id
    bastion     = aws_security_group.bastion.id
  }
}
