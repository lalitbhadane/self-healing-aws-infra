output "alb_dns_name" {
  description = "The public URL of the load balancer"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "the VPC ID"
  value       = module.vpc.vpc_id
}
