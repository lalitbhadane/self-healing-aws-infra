variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ASG"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for instances (defaults to latest Amazon Linux 2023)"
  type        = string
  default     = null
}
