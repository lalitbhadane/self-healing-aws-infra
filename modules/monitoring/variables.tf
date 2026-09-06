variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}


