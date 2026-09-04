output "alb_dns_name" {
  description = "The public URL of the load balancer"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "the VPC ID"
  value       = module.vpc.vpc_id
}

output "db_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = module.rds.db_endpoint
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}
