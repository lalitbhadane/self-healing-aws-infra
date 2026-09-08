output "db_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "rds_security_group_id" {
  description = "Security group ID of the RDS instance"
  value       = aws_security_group.rds.id
}

