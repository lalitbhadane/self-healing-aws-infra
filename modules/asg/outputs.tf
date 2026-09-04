output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "instance_security_group_id" {
  description = "Security group ID of the EC2 instances"
  value       = aws_security_group.instance.id
}
