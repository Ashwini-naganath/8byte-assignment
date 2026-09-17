output "vpc_id" {
  value = aws_vpc.main.id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "production_private_ip" {
  value = aws_instance.app.private_ip
}

output "staging_private_ip" {
  value = aws_instance.staging.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
